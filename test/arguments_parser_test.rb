# frozen_string_literal: true

require "test_helper"

class Panacea::Rails::ArgumentsParserTest < Minitest::Test
  def setup
    @subject = Class.new do
      extend Panacea::Rails::ArgumentsParser
    end
  end

  def test_it_transform_args_hash_to_string
    args_hash = { database: "postgresql", "skip-git": true }
    result_string = @subject.parse_arguments(args_hash)

    assert_equal result_string, "--database=postgresql --skip-git"
  end
end
