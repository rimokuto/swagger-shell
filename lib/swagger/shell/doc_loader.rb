module Swagger
  module Shell
    class DocLoader
      def load(url)
        api_docs = JSON.parse(Faraday.new(url: url).get.body)
        swagger_version = api_docs["swaggerVersion"] || api_docs["swagger"]

        ApiStruct.new(api_docs["basePath"]).tap do |root_api|
          # TODO: refactor
          if swagger_version == "1.2"
            api_docs["apis"].each do |api|
              api_body = JSON.parse Faraday.new(url: url + api["path"].gsub("{format}", :json.to_s)).get.body

              api_body["apis"].each do |api2|
                # 冗長なパスを排除
                path = api2["path"].gsub(/^#{Swagger::Shell.config_api.ignore_top_url}/, "")
                path_keys = path.split("/").reject {|s| s == "" }.tap {|p| p.last.gsub!(".json", "") }

                root_api.add_api(path_keys, api2["operations"].first["method"])
              end
            end
          elsif swagger_version == "2.0"
            api_docs["paths"].each do |path, methods|
              methods.each do |method, api_info|
                # TODO: ignore path
                path_keys = path.split("/").reject {|s| s == "" } # TODO: format // .tap {|p| p.last.gsub!(".json", "") }
                root_api.add_api(path_keys, method, api_info: api_info)
              end
            end
          end
        end
      end
    end
  end
end
