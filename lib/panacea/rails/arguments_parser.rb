# frozen_string_literal: true

module Panacea # :nodoc:
  module Rails # :nodoc:
    ###
    # == Panacea::Rails::ArgumentsParser
    #
    # This module is in charge Parsing Slop Arguments.
    module ArgumentsParser
      ###
      # This method builds an arguments String from the Slop args Hash.
      #
      # The string will be passed to the `rails new` command and it will be also
      # tracked if the end user agrees to share Panacea's usage information
      def parse_arguments(arguments)
        arguments.each_with_object([]) do |arg, parsed_args|
          case arg.last.class.to_s
          when "String"
            parsed_args << "--#{arg.first}=#{arg.last}"
          when "TrueClass"
            parsed_args << "--#{arg.first}"
          end
        end.join(" ")
      end
    end
  end
end
