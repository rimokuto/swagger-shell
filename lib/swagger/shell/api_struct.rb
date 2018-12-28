module Swagger
  module Shell
    module ApiGet
      def get(message = {})
        _get(api_url, message)
      end
    end

    module ApiPost
      def post(message = {})
        _post(api_url, message)
      end
    end

    module ApiPut
      def put(message = {})
        _put(api_url, message)
      end
    end

    module ApiDelete
      def delete(message = {})
        _delete(api_url, message)
      end
    end

    class ApiStruct
      attr_reader :parent, :children

      def initialize(key, parent = nil)
        @key = key
        @parent = parent
        @children = []
      end

      def root?
        @parent.nil?
      end

      def api_key
        @key
      end

      def method_key
        root? ? "api" : @key
      end

      def add_api(path_keys, method, api_info: nil)
        find_or_create_api_struct(path_keys).tap do |api_struct|
          api_struct.add_api_module(method) if api_struct
        end
      end

      def api_list
        @children.each_with_object({}) do |key, hash|
          hash.merge!(instance_variable_get("@#{key}").api_list)
        end.tap do |hash|
          api_methods.each do |api_method|
            hash[api_method] = ""
          end
        end
      end

      def api_url
        # TODO: Is there simply + no problem?　If possible, pass from outside.
        Swagger::Shell.config_api.ignore_top_url + api_ancestors.map(&:api_key).join("/")
      end

      def api_methods
        %i[get post put delete].map do |method|
          (api_ancestors.map(&:method_key) << method).join(".") if singleton_class.include? self.class.module_class(method)
        end.compact
      end

      def api_ancestors
        loop.inject([self]) do |parents|
          break parents if parents.last.parent.nil?
          parents << parents.last.parent
          parents
        end.reverse
      end

      def add_api_module(method)
        extend self.class.module_class(method)
      end

      def child(path_key)
        # not implement url with id (i.g.: hoge/111/age)
        # TODO: (i.g.: api.hoge(111).age.post )
        return nil if /\A\{\w+\}\Z/.match(path_key)

        unless respond_to? path_key
          instance_variable_set("@#{path_key}", ApiStruct.new(path_key,self))
          instance_eval <<-RUBY
            def self.#{path_key}
              @#{path_key}
            end
          RUBY
          @children << path_key.to_sym
        end

        instance_variable_get("@#{path_key}")
      end

      def user
        Swagger::Shell.user
      end

      def self.module_class(method)
        camelize_name = method.to_s.dup.tap {|s| s[0] = s[0].upcase }
        Swagger::Shell.const_get("Api#{camelize_name}")
      end

      private

      def hook_request_body(body)
        body
      end

      def hook_request_headers
        Swagger::Shell.config_env.request_headers.to_h
      end

      def hook_response_body(body)
        # TODO: need to implement expect for json
        JSON.parse body, symbolize_names: true
      end

      def find_or_create_api_struct(path_keys)
        path_keys.inject(self) do |api_struct, path_key|
          break nil if api_struct.nil?

          api_struct.child(path_key)
        end
      end

      def _get(url, message = {})
        _request(:get, url, message)
      end

      def _post(url, message = {})
        _request(:post, url, message)
      end

      def _put(url, message = {})
        _request(:put, url, message)
      end

      def _delete(url, message = {})
        _request(:delete, url, message)
      end

      def _request(method, url, params = {})
        res = begin
          client = Faraday.new(:url => Swagger::Shell.config_env.api_url)
          client.public_send(method) do |req|
            req.url url
            hook_request_headers.each do |k, v|
              req.headers[k] = v.to_s
            end
            req.body = hook_request_body(params).to_json
          end
        rescue => e
          raise e
        end

        hook_response_body(res.body)
      end
    end
  end
end
