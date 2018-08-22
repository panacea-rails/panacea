# frozen_string_literal: true

require "yaml"

ROOT_DIR = File.expand_path("../../../", __dir__)

# Add lib/panacea/rails dir to the source paths so
# Thor can access our templates files.
source_paths.unshift(ROOT_DIR)

# Read .panacea configurations file
configurations_file = File.join(ROOT_DIR, ".panacea")
@panacea = YAML.safe_load(File.read(configurations_file))

# Starting Thor commands:

# Copy Gemfile
template "templates/Gemfile.tt", "Gemfile", force: true

# Copy Rubocop
template "templates/rubocop.tt", ".rubocop.yml"

# Create Test Support dir
empty_directory "test/support"

# Configure simplecov
template "templates/simplecov.tt", "test/support/simplecov.rb"

# Overwrite Test Helper
template "templates/test_helper.tt", "test/test_helper.rb", force: true

# Overwrite Applicatio System Test Case to Healess Chrome
template("templates/application_system_test.tt", "test/application_system_test_case.rb", force: true) if @panacea.dig("headless_chrome")

# Configure Letter Opener
environment nil, env: "development" do
  <<~CONFS
    # Settings for Letter Opener
    config.action_mailer.delivery_method = :letter_opener
    config.action_mailer.perform_deliveries = true
    config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  CONFS
end

# Run all initializers
after_bundle do
  run "spring stop"

  # Add money-rails initializer if needed
  generate "money_rails:initializer" if @panacea.dig("money_rails")

  # Setup devise if needed
  if @panacea.dig("devise")
    model_name = @panacea.dig("devise_model_name").downcase
    plural_model_name = model_name.downcase.pluralize

    generate "devise:install"
    generate "devise", model_name
    generate "devise:views", plural_model_name if @panacea.dig("devise_override_views")
  end

  # Fix rails new style offenses
  run "rubocop -a --format=simple"
end
