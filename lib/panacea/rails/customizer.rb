# frozen_string_literal: true

require "tty/prompt"
require "yaml"
require_relative "stats"

module Panacea # :nodoc:
  module Rails # :nodoc:
    ###
    # == Panacea::Rails::Customizer
    #
    # This class is in charge of asking the configuration questions.
    # It saves the answers on the .panacea file.
    class Customizer
      # rubocop:disable Style/FormatStringToken

      ###
      # ASCII art displayed at the start of the Panacea command
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

      ###
      # This method receives the App's name and the passed arguments.
      #
      # It creates a new instance of Panacea::Rails::Customizer class and
      # executes the start instance method.
      def self.start(app_name, passed_args)
        new(app_name, passed_args).start
      end

      ###
      # A Hash with the questions loaded from config/questions.yaml file
      attr_reader :questions

      ###
      # A TTY::Prompt instance
      attr_reader :prompt

      ###
      # A Hash where each question's answer is stored
      attr_reader :answers

      ###
      # App's name
      attr_reader :app_name

      ###
      # A String with the arguments passed to the Panacea command
      attr_reader :passed_args

      ###
      # Panacea::Rails::Customizer initialize method
      #
      # A TTY::Prompt instance is used as default prompt.
      def initialize(app_name, passed_args, prompt: TTY::Prompt.new)
        @app_name = app_name
        @passed_args = passed_args
        @answers = {}
        @prompt = prompt
      end

      ###
      # This method shows the Welcome message.
      # Then, it ask the questions using the default prompt.
      # It also tracks the answers only if the end user agrees to.
      # At the end, it saves the answers to the .panacea file.
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

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Security/Eval
      def ask_question(key, question)
        title = question.dig("title")
        default = question.dig("default")
        condition = question.dig("condition")

        unless condition.nil?
          return unless eval(condition)
        end

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
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Security/Eval

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
