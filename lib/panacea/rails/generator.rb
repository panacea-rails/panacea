# frozen_string_literal: true

module Panacea # :nodoc:
  module Rails # :nodoc:
    # rubocop:disable Metrics/ClassLength

    ###
    # == Panacea::Rails::Generator
    #
    # This class is in charge of grouping all the actions to be executed via Panacea::Rails::Template
    class Generator
      ###
      # The Rails::Generators::AppGenerator context
      attr_reader :app_generator

      ###
      # A String with Panacea's installation directory
      attr_reader :root_dir

      ###
      # The Panacea's Configuration Hash
      attr_reader :config

      ###
      # This methods receive the context of the  Rails::Generators::AppGenerator
      # So it executes all methods against it.
      #
      # It also receives the Panacea's Config Hash and the Panacea's Gem Root dir
      # in order to update  Rails::Generators::AppGenerator source paths.
      def initialize(app_generator, panacea_config, root_dir)
        @app_generator = app_generator
        @config = panacea_config
        @app_generator.instance_variable_set :@panacea, @config
        @root_dir = root_dir
      end

      ###
      # Send any unknown method to the Rails::Generators::AppGenerator context.
      # That context also knows Thor actions.
      def method_missing(method_name, *args, &block)
        super unless app_generator.respond_to?(method_name)
        app_generator.send(method_name, *args, &block)
      end

      ###
      # Whitelist of Rails::Generator::AppGenerator and Thor methods.
      #
      # Add here any new method to be used from Thor / Rails Generator
      def respond_to_missing?(method_name, include_private = false)
        %i[
          after_bundle generate rails_command template
          run git source_paths empty_directory append_to_file
          environment application say inject_into_class
          inject_into_file
        ].include?(method_name) || super
      end

      ###
      # All the methods passed via block are executed on the Rails::Generators::AppGenerator
      # after_bundle hook.
      def after_bundle_hook
        after_bundle do
          run "spring stop"
          yield self
        end
      end

      ###
      # Update Rails::Generators::AppGenerator source paths, making Panacea's Templates under
      # templates/ directory available.
      def update_source_paths
        source_paths.unshift(root_dir)
      end

      ###
      # Update the Gemfile
      def copy_gemfile
        template "templates/Gemfile.tt", "Gemfile", force: true
      end

      ###
      # Update the README.md
      def copy_readme
        template "templates/README.tt", "README.md", force: true
      end

      ###
      # Creates the PANACEA.md file
      def generate_panacea_document
        template "templates/PANACEA.tt", "PANACEA.md"
      end

      ###
      # Create .rubocop.yml in generated Rails app.
      def setup_rubocop
        template "templates/rubocop.tt", ".rubocop.yml"
      end

      ###
      # Setup the test suite (rspec or minitest).
      def setup_test_suite
        return unless config.dig("test_suite") == "rspec"

        generate "rspec:install"
        run "rm -r test"
      end

      ###
      # Setup Simplecov based on the chosen test suite.
      def setup_simplecov
        path = if config.dig("test_suite") == "minitest"
                 "test/support"
               else
                 "spec/support"
               end

        template "templates/simplecov.tt", "#{path}/simplecov.rb"
        append_to_file ".gitignore", "\n# Ignore Coverage files \n/coverage\n"
      end

      ###
      # Override test helper based on the chosen test suite.
      def override_test_helper
        if config.dig("test_suite") == "minitest"
          template "templates/minitest_test_helper.tt", "test/test_helper.rb", force: true
        else
          template "templates/rspec_test_helper.tt", "spec/rails_helper.rb", force: true
        end
      end

      ###
      # Setup Headless Chrome Driver based on chosen test suite.
      def override_application_system_test
        return unless config.dig("test_suite") == "minitest"
        template "templates/application_system_test.tt", "test/application_system_test_case.rb", force: true
      end

      ###
      # Setup OJ gem.
      def setup_oj
        template "templates/oj_initializer.tt", "config/initializers/oj.rb"
      end

      ###
      # Setup Dotenv gem.
      def setup_dotenv
        template "templates/dotenv.tt", ".env"
        append_to_file ".gitignore", "\n# Ignore .env file \n.env\n"
      end

      ###
      # Setup chosen Background Job gem.
      def setup_background_job
        background_job = config.dig("background_job")

        application nil do
          <<~CONFS
            # Default adapter queue
            config.active_job.queue_adapter = :#{background_job}

          CONFS
        end

        if background_job == "sidekiq"
          route "mount Sidekiq::Web => '/sidekiq'"
          route "require 'sidekiq/web'"
        elsif background_job == "resque"
          route "mount Resque::Server, at: '/jobs'"
          route "require 'resque/server'"

          template "templates/Rakefile.tt", "Rakefile", force: true
        end
      end

      ###
      # Setup the application's timezone.
      def setup_timezone
        timezone = config.dig("timezone").split("-").first.chomp(" ")

        application nil do
          <<~CONFS
            # Default timezone
            config.time_zone = "#{timezone}"

          CONFS
        end
      end

      ###
      # Setup the application's locale.
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

      ###
      # Create database
      def create_database
        rails_command "db:create"
      end

      ###
      # Setup Bullet gem
      def setup_bullet
        environment nil, env: "development" do
          <<~CONFS
            # Settings for Bullet gem
            config.after_initialize do
              Bullet.enable        = true
              Bullet.alert         = true
              Bullet.bullet_logger = true
              Bullet.console       = true
              Bullet.rails_logger  = true
              Bullet.add_footer    = true
            end

          CONFS
        end
      end

      ###
      # Setup letter_opener gem.
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

      ###
      # Setup Devise gem.
      def setup_devise
        model_name = config.dig("devise_model_name").downcase
        plural_model_name = model_name.downcase.pluralize

        generate "devise:install"
        generate "devise", model_name
        generate "devise:views", plural_model_name if config.dig("devise_override_views")

        rails_command "db:migrate"
      end

      ###
      # Setup booswatch-rails gem.
      def setup_bootswatch
        run "rm app/assets/stylesheets/application.css"
        template "templates/bootswatch/stylesheets/application.scss.tt", "app/assets/stylesheets/application.scss"

        inject_into_file "app/assets/javascripts/application.js", after: "//= require turbolinks" do
          "\n//= require jquery
           \n//= require bootstrap-sprockets"
        end

        run "rm app/views/layouts/application.html.erb"

        template "templates/bootswatch/views/shared/_navbar.html.haml",
          "app/views/shared/_navbar.html.haml"
        template "templates/bootswatch/views/shared/_flash_messages.html.haml",
          "app/views/shared/_flash_messages.html.haml"
        template "templates/bootswatch/views/layouts/application.html.haml",
          "app/views/layouts/application.html.haml", force: true

        generate "controller home index"
        inject_into_file "config/routes.rb", "\nroot to: 'home#index'", after: "Rails.application.routes.draw do"

        directory "templates/devise/views/", "app/views/devise/", force: true if config.dig("devise_override_views")
      end

      ###
      # Setup money_rails gem.
      def setup_money_rails
        generate "money_rails:initializer"
      end

      ###
      # Setup Kaminari gem.
      def setup_kaminari
        generate "kaminari:config"
      end

      ###
      # Setup webpacker gem.
      def setup_webpack
        rails_command "webpacker:install"
        rails_command "webpacker:install:#{config.dig('webpack_type')}" if config.dig("webpack_type") != "none"
      end

      ###
      # Setup foreman gem
      def setup_foreman
        run "gem install foreman" unless system("gem list -i foreman")

        template "templates/Procfile.tt", "Procfile"
      end

      ###
      # Setup Pundit gem
      def setup_pundit
        generate "pundit:install"
        inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  include Pundit\n"
      end

      ###
      # Creates chosen Git hook.
      def setup_githook
        hook_file = ".git/hooks/#{config.dig('githook_type')}"
        template "templates/githook.tt", hook_file
        run "chmod ug+x #{hook_file}"
      end

      ###
      # This needs to be run before commiting.
      #
      # Fix existing application's style offenses.
      def fix_offenses!
        run "rubocop -a --format=simple"
      end

      ###
      # Commit only if end users want to.
      def commit!
        git add: "."
        git commit: "-m '#{config.dig('commit_msg')}'"
      end

      ###
      # Display good bye message.
      def bye_message
        message = "Panacea's work is done, enjoy!"
        say "\n\n\e[34m#{message}\e[0m"
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
