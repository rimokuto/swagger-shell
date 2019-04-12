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
      # option
      # p: output parameter name
      # s: output summary
      #
      # no option output summary.
      #
      # e.g.:
      # swagger-shell(main)> apis :ps
      def apis(option = :ps)
        option = option.to_s

        with_parameter = option.include?("p")
        with_summary = option.include?("s") || option.size.zero?

        api_list = api.api_list
        max_key_size = api_list.keys.map(&:size).max
        api_list.sort.each do |api, operation|
          comments = []
          comments << operation.summary if with_summary
          comments << "(#{(operation.parameters || []).map {|p| p["name"][8..-2] }.map {|n| "#{n}:" }.join(", ")})" if with_parameter

          puts "#{api}#{" " * (max_key_size - api.size)} # #{comments.join(" ")}"
        end

        nil
      end
    end
  end
end
