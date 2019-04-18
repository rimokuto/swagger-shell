require "swagger/shell/api_struct"
require "swagger/shell/doc_loader"
require "swagger/shell/interface"
require "swagger/shell/user"
require "swagger/shell/version"
require "json"

module Swagger
  module Shell
    class << self
      attr_reader :env, :config_api, :config_pry

      def env=(env)
        @env = env
      end

      def config_env=(config)
        @config_env_store = hash_to_struct(config)
      end

      def config_env
        @config_env ||= @config_env_store[env].tap do |config|
          config.docs_url = File.join(config.api_url, config.docs_url) unless config.docs_url.start_with? "http"
        end
      end

      def config_api=(config)
        @config_api = hash_to_struct(config)
      end

      def config_pry=(config)
        @config_pry = hash_to_struct(config).tap do |config|
          config.home = config.home.gsub(/^~/, Dir.home) if config.home.start_with?("~/")
          config.history_path = File.join(config.home, config.history_file)
          config.users_path = File.join(config.home, config.users_file)
        end
      end

      def user
        @user ||= User.new
      end

      def api
        @aip ||= DocLoader.new.load(config_env.docs_url)
      end

      def registered_interfaces
        @registered_interfaces ||= []
      end

      def register_interface(interface_module)
        registered_interfaces << interface_module
      end

      def start(main, env = nil)
        self.env = env || :default
        main.extend Swagger::Shell::Interface
        registered_interfaces.each do |interface|
          main.extend interface
        end
        main.start_shell
      end

      def hash_to_struct(hash)
        JSON.parse hash.to_json, object_class: OpenStruct
      end
    end
  end
end
