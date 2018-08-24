# frozen_string_literal: true

require "test_helper"
require "fileutils"

class Panacea::Rails::CustomizerTest < Minitest::Test
  ROOT_DIR = File.expand_path("..", __dir__)

  def setup
    @panacea_config_file = File.join(ROOT_DIR, ".panacea")
    @subject = Panacea::Rails::Customizer.new
  end

  def test_it_generates_a_config_file
    FileUtils.rm(@panacea_config_file) if File.exist?(@panacea_config_file)
    @subject.start

    assert File.exist?(@panacea_config_file)
  end
end
