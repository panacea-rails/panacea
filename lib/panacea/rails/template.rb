# frozen_string_literal: true

###
# == Panacea::Rails::Template
#
# Template passed to the rails new command.
#
# If you want more information about what's happening you can read Panacea::Rails::Generator docs.

require "yaml"
require_relative "generator"

###
# Panacea's Installation directory
ROOT_DIR = File.expand_path("../../../", __dir__)

# Read .panacea configurations file
configurations_file = File.join(ROOT_DIR, ".panacea")
panacea_config = YAML.safe_load(File.read(configurations_file))
panacea_config["ruby_version"] = RUBY_VERSION

# Start running Panacea Generator Actions via Rails Generator / Thor
panacea_generator = Panacea::Rails::Generator.new(self, panacea_config, ROOT_DIR)

panacea_generator.update_source_paths
panacea_generator.copy_gemfile
panacea_generator.copy_readme
panacea_generator.generate_panacea_document
panacea_generator.run_bundle

panacea_generator.setup_rubocop
panacea_generator.setup_letter_opener
panacea_generator.setup_timezone
panacea_generator.setup_default_locale
panacea_generator.create_database
panacea_generator.setup_oj if panacea_config.dig("oj")
panacea_generator.setup_dotenv if panacea_config.dig("dotenv")
panacea_generator.setup_bullet
panacea_generator.setup_test_suite
panacea_generator.override_test_helper
panacea_generator.setup_simplecov
panacea_generator.setup_background_job if panacea_config.dig("background_job") != "none"
panacea_generator.override_application_system_test if panacea_config.dig("headless_chrome")
panacea_generator.setup_devise if panacea_config.dig("devise")
panacea_generator.setup_money_rails if panacea_config.dig("money_rails")
panacea_generator.setup_kaminari if panacea_config.dig("kaminari")
panacea_generator.setup_foreman if panacea_config.dig("foreman")
panacea_generator.setup_pundit if panacea_config.dig("pundit")

panacea_generator.fix_offenses!
panacea_generator.commit! if panacea_config.dig("autocommit")
panacea_generator.setup_githook if panacea_config.dig("githook") && !options[:skip_git]
panacea_generator.bye_message
