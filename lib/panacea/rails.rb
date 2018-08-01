# frozen_string_literal: true

require "slop"
require "panacea/rails/version"

module Panacea
  module Rails
    class << self
      def init
        opts = Slop.parse do |o|
          o.banner = "usage: panacea your-app-name [options]"

          o.string "-d", "--database", "options (mysql/postgresql/sqlite3/oracle/frontbase/im_db/sqlserver/jdbcmysql/jdbcsqlite3/jdbcpostgresql/jdbc)", default: "postgres"

          o.on "-v", "--version" do
            puts Panacea::Rails::VERSION
            exit
          end

          o.on "-h", "--help" do
            puts o
            exit
          end
        end

        puts opts
      end
    end
  end
end
