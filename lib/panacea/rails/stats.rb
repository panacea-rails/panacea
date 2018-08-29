# frozen_string_literal: true

require "json"
require "net/http"

module Panacea
  module Rails
    class Stats
      attr_reader :params

      API_BASE = "https://stats.panacea.website/statistics"

      def self.track(params)
        new(params)
      end

      def initialize(params)
        @params = params
        track
      end

      def track
        request_async_post(params)
      end

      private

      def request_async_post(params)
        Thread.new do
          request_post(params)
        end
      end

      def request_post(params)
        uri = URI(API_BASE)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          request = Net::HTTP::Post.new(uri)
          request["Accept"] = "application/json"
          request["Content-Type"] = "application/json"
          request.body = params.to_json

          http.request(request)
        end

        response.code == "201" || response.code != "422"
      rescue Net::OpenTimeout, Errno::ECONNREFUSED
        false
      end
    end
  end
end
