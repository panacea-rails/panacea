# frozen_string_literal: true

require_relative "arguments_parser"
require_relative "customizer"

module Panacea # :nodoc:
  module Rails # :nodoc:
    ###
    # == Panacea::Rails::Runner
    #
    # This module is where Panacea's work start.
    module Runner
      extend ArgumentsParser

      class << self
        ###
        # This method receives the App's name and the arguments passed to Panacea command.
        #
        # It uses the Panacea::Rails::ArgumentsParser.parse_arguments method to transform the passed arguments.
        #
        # It also starts the Panacea::Rails::Customizer which is in charge of asking the configuration questions.
        #
        # Then, it appends the Panacea's Template option to the list of parsed arguments.
        #
        # It finally runs the rails new command with the App's name and the final list of arguments.
        def call(app_name, rails_args)
          parsed_arguments = parse_arguments(rails_args)
          Customizer.start(app_name, parsed_arguments.dup)

          panacea_template = __dir__ + "/template.rb"
          parsed_arguments << " --template=#{panacea_template}"
          parsed_arguments = parsed_arguments.split(" ")

          system("rails", "new", app_name, *parsed_arguments)
        end
      end
    end
  end
end
