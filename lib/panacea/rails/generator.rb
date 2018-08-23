# frozen_string_literal: true

module Panacea
  module Rails
    # rubocop:disable Metrics/ClassLength
    class Generator
      attr_reader :app_generator, :root_dir, :config

      def initialize(app_generator, panacea_config, root_dir)
        @app_generator = app_generator
        @config = panacea_config
        @app_generator.instance_variable_set :@panacea, @config
        @root_dir = root_dir
      end

      def method_missing(method_name, *args, &block)
        super unless app_generator.respond_to?(method_name)
        app_generator.send(method_name, *args, &block)
      end

      def respond_to_missing?(method_name, include_private = false)
        # Add here any new method to be used from Thor / Rails Generator
        %i[
          after_bundle generate rails_command template
          run git source_paths empty_directory append_to_file
          environment application
        ].include?(method_name) || super
      end

      def after_bundle_hook
        after_bundle do
          run "spring stop"
          yield self
        end
      end

      def update_source_paths
        source_paths.unshift(root_dir)
      end

      def copy_gemfile
        template "templates/Gemfile.tt", "Gemfile", force: true
      end

      def setup_rubocop
        template "templates/rubocop.tt", ".rubocop.yml"
      end

      def create_test_support_dir
        empty_directory "test/support"
      end

      def setup_simplecov
        template "templates/simplecov.tt", "test/support/simplecov.rb"
      end

      def override_test_helper
        template "templates/test_helper.tt", "test/test_helper.rb", force: true
      end

      def override_application_system_test
        template "templates/application_system_test.tt", "test/application_system_test_case.rb", force: true
      end

      def setup_oj
        template "templates/oj_initializer.tt", "config/initializers/oj.rb"
      end

      def setup_dotenv
        template "templates/dotenv.tt", ".env"
        append_to_file ".gitignore", "\n# Ignore .env file \n.env\n"
      end

      def setup_timezone
        timezone = config.dig("timezone").split("-").first.chomp(" ")

        application nil do
          <<~CONFS
            # Default timezone
            config.time_zone = "#{timezone}"

          CONFS
        end
      end

      def setup_default_locale
        locale = config.dig("locale").split("- ").last

        application nil do
          <<~CONFS
            # Default i18n locale
            config.i18n.default_locale = :#{locale}

          CONFS
        end

        template "templates/default_locale.tt", "config/locales/#{locale}.yml" if locale != "en"
      end

      def setup_letter_opener
        environment nil, env: "development" do
          <<~CONFS
            # Settings for Letter Opener
            config.action_mailer.delivery_method = :letter_opener
            config.action_mailer.perform_deliveries = true
            config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

          CONFS
        end
      end

      def setup_devise
        model_name = config.dig("devise_model_name").downcase
        plural_model_name = model_name.downcase.pluralize

        generate "devise:install"
        generate "devise", model_name
        generate "devise:views", plural_model_name if config.dig("devise_override_views")
      end

      def setup_money_rails
        generate "money_rails:initializer"
      end

      def setup_kaminari
        generate "kaminari:config"
      end

      def setup_webpack
        rails_command "webpacker:install"
        rails_command "webpacker:install:#{config.dig('webpack_type')}" if config.dig("webpacker_type") != "none"
      end

      def setup_githook
        hook_file = ".git/hooks/#{config.dig('githook_type')}"
        template "templates/githook.tt", hook_file
        run "chmod ug+x #{hook_file}"
      end

      def fix_offenses!
        run "rubocop -a --format=simple"
      end

      def commit!
        git add: "."
        git commit: "-m '#{config.dig('commit_msg')}'"
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
