# frozen_string_literal: true

require "slop"
require "panacea/rails/version"
require "panacea/rails/runner"

module Panacea
  module Rails
    class << self
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/LineLength
      def init
        opts = Slop.parse do |o|
          o.banner = "usage: panacea your-app-name [options]"

          o.string "-d", "--database", "# Options (mysql/postgresql/sqlite3/oracle/frontbase/im_db/sqlserver/jdbcmysql/jdbcsqlite3/jdbcpostgresql/jdbc)", default: "postgresql"
          o.bool "--skip-namespace", "# Skip namespace (affects only isolated applications)", default: false
          o.bool "--skip-git", "# Skip .gitignore file", default: false

          o.on "-v", "--version" do
            puts Panacea::Rails::VERSION
            exit
          end

          o.on "-h", "--help" do
            puts o
            exit
          end
        end

        return puts(opts) if opts.arguments.empty?

        Runner.call(opts.arguments.first, opts.to_hash)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/LineLength
    end
  end
end
