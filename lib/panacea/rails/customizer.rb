# frozen_string_literal: true

require "tty/prompt"
require "yaml"
require_relative "stats"

module Panacea
  module Rails
    class Customizer
      # rubocop:disable Style/FormatStringToken
      WELCOME_MESSAGE = <<~MSG
         _____________________________
        |            .....      //    |
        |        _d^^^^^^^^^b_ //     |
        |     .d''           ``       |
        |   .p'                      /|
        |  .d'                     .//| Welcome to Panacea!
        | .d'  -----------      - `b. | You are about to boost your fresh
        | :: --------------------- :: | %{app_name} Rails App
        | :: --- P A N A C E A --- :: |
        | :: --------------------- :: | Full documentation here: https://panacea.website
        | `p. ------------------- .q' | Most of the defaults are false or disabled,
        |  `p. ----------------- .q'  | if you want to enable a feature please answer yes
        |   `b. --------------- .d'   |
        |     `q.. -------- ..p'      |
        |        ^q........p^         |
        |____________''''_____________|

      MSG
      # rubocop:enable Style/FormatStringToken

      def self.start(app_name, passed_args)
        new(app_name, passed_args).start
      end

      attr_reader :questions, :prompt, :answers, :app_name, :passed_args

      def initialize(app_name, passed_args, prompt: TTY::Prompt.new)
        @app_name = app_name
        @passed_args = passed_args
        @answers = {}
        @prompt = prompt
      end

      def start
        welcome_message
        ask_questions
        track_answers
        save_answers
      end

      private

      def welcome_message
        message = format(WELCOME_MESSAGE, app_name: app_name.capitalize)
        prompt.say(message, color: :blue)
      end

      def ask_questions(questions = load_questions)
        questions.each do |key, question|
          answer = ask_question(key, question)
          subquestions = question.dig("subquestions")

          ask_questions(subquestions) if !subquestions.nil? && answer
        end
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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

      def track_answers
        share_usage_info = answers.delete("share_usage_info")
        return unless share_usage_info

        params = answers.dup
        params[:ruby_version] = RUBY_VERSION
        params[:arguments] = passed_args
        Stats.track(params)
      end
    end
  end
end
