# frozen_string_literal: true

require "yaml"

root_dir = File.expand_path("../../../", __dir__)
configurations_file = File.join(root_dir, ".panacea")

configs = YAML.safe_load(File.read(configurations_file))

puts configs.inspect
