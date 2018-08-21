# frozen_string_literal: true

module Panacea
  module Rails
    module ArgumentsParser
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
