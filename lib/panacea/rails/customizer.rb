# frozen_string_literal: true

require "tty/prompt"
require "yaml"

module Panacea
  module Rails
    class Customizer
      def self.start
        new.start
      end

      attr_reader :questions, :prompt, :answers

      def initialize(prompt: TTY::Prompt.new)
        @answers = {}
        @prompt = prompt
      end

      def start
        ask_questions
        save_answers
      end

      private

      def ask_questions(questions = load_questions)
        questions.each do |key, question|
          answer = ask_question(key, question)
          subquestions = question.dig("subquestions")

          ask_questions(subquestions) if !subquestions.nil? && answer
        end
      end

      # rubocop:disable Metrics/AbcSize
      def ask_question(key, question)
        title = question.dig("title")
        default = question.dig("default")
        answer = nil

        case question.dig("type")
        when "boolean"
          answer = prompt.yes?(title) { |q| q.default(default) }
        when "range"
          answer = prompt.ask(title, default: default) { |q| q.in(question.dig("range")) }
        when "text"
          answer = prompt.ask(title, default: default)
        when "select"
          answer = prompt.select(title, question.dig("options"))
        else
          raise StandardError, "Question type not supported."
        end

        update_answer(key, answer)
      end
      # rubocop:enable Metrics/AbcSize

      def update_answer(key, answer)
        answers[key] = answer
      end

      def load_questions
        questions_file = File.join(File.expand_path("../../../config", __dir__), "questions.yml")
        @questions = YAML.safe_load(File.read(questions_file))
      end

      def save_answers
        root_dir = File.expand_path("../../../", __dir__)
        configurations_file = File.join(root_dir, ".panacea")

        File.open(configurations_file, "w") { |f| f.write(answers.to_yaml) }
      end
    end
  end
end
