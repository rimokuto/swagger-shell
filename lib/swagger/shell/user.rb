module Swagger
  module Shell
    class User
      attr_reader :id, :info

      def load_sample
        id = list.sample
        return if id.nil?
        load_by(id)
      end

      def load_by(id)
        @id = id
        @info = YAML.load_file("#{users_path}/#{Swagger::Shell.env}.#{@id}.yml")
      end

      def list
        Dir.glob("#{users_path}/#{Swagger::Shell.env}.*.yml").map {|f| File.basename(f, ".yml").gsub(/^#{Swagger::Shell.env}\./, "") }
      end

      def clean!
        Dir.glob("#{users_path}/#{Swagger::Shell.env}.*.yml") {|f| File.delete f }
        @info = nil
      end

      def save(id, info)
        @id = id
        @info = info

        save_to_yml(@id, @info)
      end

      def create
        # need to override
      end

      def login
        # need to override
      end

      # patch
      def debug
        command = "open #{Swagger::Shell.config_env.debug_url}/#{id}"
        puts command
        `#{command}`
        nil
      end

      private

      def save_to_yml(filename, data)
        FileUtils.mkdir_p(users_path)
        open("#{users_path}/#{Swagger::Shell.env}.#{filename}.yml","w") do |f|
          YAML.dump(data, f)
        end
      end

      def users_path
        Swagger::Shell.config_pry.users_path
      end
    end
  end
end