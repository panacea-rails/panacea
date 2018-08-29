# frozen_string_literal: true

require "slop"
require "panacea/rails/version"
require "panacea/rails/runner"

module Panacea
  module Rails
    class << self
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/LineLength, Metrics/BlockLength
      def init
        opts = Slop.parse do |o|
          o.banner = "usage: panacea your-app-name [options]"
          o.separator ""
          o.string "-d", "--database", "# Options (mysql/postgresql/sqlite3/oracle/frontbase/im_db/sqlserver/jdbcmysql/jdbcsqlite3/jdbcpostgresql/jdbc)", default: "postgresql"
          o.bool "--skip-namespace", "# Skip namespace (affects only isolated applications)", default: false
          o.bool "--skip-yarn", "# Don't use Yarn for managing JavaScript dependencies", default: false
          o.bool "--skip-git", "# Skip .gitignore file", default: false
          o.bool "--skip-keeps", "# Skip source control .keep files", default: false
          o.bool "--skip-action-mailer", "# Skip Action Mailer files", default: false
          o.bool "--skip-active-record", "# Skip Active Record files", default: false
          o.bool "--skip-active-storage", "# Skip Active Storage files", default: false
          o.bool "--skip-puma", "# Skip Puma related files", default: false
          o.bool "--skip-action-cable", "# Skip Action Cable files", default: false
          o.bool "--skip-sprockets", "# Skip Sprockets files", default: false
          o.bool "--skip-spring", "# Don't install Spring application preloader", default: false
          o.bool "--skip-listen", "# Don't generate configuration that depends on the listen gem", default: false
          o.bool "--skip-coffee", "# Don't use CoffeeScript", default: false
          o.bool "--skip-javascript", "# Skip JavaScript files", default: false
          o.bool "--skip-turbolinks", "# Skip turbolinks gem", default: false
          o.bool "--skip-test", "# Skip test files", default: false
          o.bool "--skip-system-test", "# Skip system test files", default: false
          o.bool "--skip-bootsnap", "# Skip bootsnap gem", default: false
          o.bool "--dev", "# Setup the application with Gemfile pointing to your Rails checkout", default: false
          o.bool "--edge", "# Setup the application with Gemfile pointing to Rails repository", default: false
          o.string "--rc", "# Path to file containing extra configuration options for rails command", default: nil
          o.bool "--no-rc", "# Skip loading of extra configuration options from .railsrc file", default: false
          o.bool "--api", "# Preconfigure smaller stack for API only apps", default: false
          o.bool "--skip-bundle", "# Don't run bundle install", default: false
          o.separator ""
          o.separator "Runtime options:"
          o.bool "--force", "# Overwrite files that already exist", default: false
          o.bool "--pretend", "# Run but do not make any changes", default: false
          o.bool "--quiet", "# Suppress status output", default: false
          o.bool "--skip", "# Skip files that already exist", default: false
          o.separator ""
          o.separator "Panacea options:"
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
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/LineLength, Metrics/BlockLength
    end
  end
end
