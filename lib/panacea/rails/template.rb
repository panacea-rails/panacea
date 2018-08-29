# frozen_string_literal: true

require "yaml"
require_relative "generator"

ROOT_DIR = File.expand_path("../../../", __dir__)

# Read .panacea configurations file
configurations_file = File.join(ROOT_DIR, ".panacea")
panacea_config = YAML.safe_load(File.read(configurations_file))
panacea_config["ruby_version"] = RUBY_VERSION

# Start running Panacea Generator Actions via Rails Generator / Thor
panacea_generator = Panacea::Rails::Generator.new(self, panacea_config, ROOT_DIR)

panacea_generator.update_source_paths
panacea_generator.copy_gemfile
panacea_generator.setup_rubocop
panacea_generator.setup_letter_opener
panacea_generator.setup_timezone
panacea_generator.setup_default_locale
panacea_generator.setup_oj if panacea_config.dig("oj")
panacea_generator.setup_dotenv if panacea_config.dig("dotenv")

panacea_generator.after_bundle_hook do |generator|
  generator.setup_test_suite
  generator.override_test_helper
  generator.setup_simplecov
  generator.setup_background_job if panacea_config.dig("background_job") != "none"
  generator.override_application_system_test if panacea_config.dig("headless_chrome")
  generator.setup_devise if panacea_config.dig("devise")
  generator.setup_money_rails if panacea_config.dig("money_rails")
  generator.setup_kaminari if panacea_config.dig("kaminari")
  generator.setup_webpack if panacea_config.dig("webpack")

  # This should be always at the end
  generator.fix_offenses!
  generator.commit! if panacea_config.dig("autocommit")
  generator.setup_githook if panacea_config.dig("githook") && !options[:skip_git]

  generator.bye_message
end
