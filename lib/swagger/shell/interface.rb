require "pry"
require "json"
require "faraday"
require "fileutils"
require "yaml"

module Swagger
  module Shell
    module Interface
      def start_shell
        Pry.config.prompt_name = Swagger::Shell.config_pry.prompt_name || "swagger-shell"

        FileUtils.mkdir_p(Swagger::Shell.config_pry.home)
        Pry.config.history.file = Swagger::Shell.config_pry.history_path || "~/.swagger-shell/history"

        bootstrap

        Pry.history.load
        Pry.start
      end

      def api
        Swagger::Shell.api
      end

      def user
        Swagger::Shell.user
      end

      def bootstrap
        user.load_sample
        begin
          if user.info.nil?
            user.create
            puts "create user_id: #{user.id}"
          else
            user.login
            puts "load user_id: #{user.id}"
          end
        rescue
          puts "failed load user_id: #{user.id}"
        end
      end

      # output API list
      #
      # option # TODO: implement
      # p: output parameter name
      # s: output summary
      #
      # no option output summary.
      #
      # e.g.:
      # swagger-shell(main)> apis :p
      def apis(option = "")
        option = option.to_s

        with_parameter = option.include?("p")
        with_summary = option.include?("s") || option.size.zero?

        api_list = api.api_list
        max_key_size = api_list.keys.map(&:size).max
        api_list.sort.each do |api, operation|
          output = "#{api}#{" " * (max_key_size - api.size)}"
          output += " # #{(operation["parameters"] || []).map {|p| p["name"][8..-2] }.join(" ")}" if with_parameter
          output += " # #{operation["summary"]}" if with_summary
          puts output
        end
        nil
      end
    end
  end
end
