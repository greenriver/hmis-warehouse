###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative 'sql_server_base'

# Lightweight connectivity-check model used by Rds#wait_for_database!
# Creates a simple `db_up` table with an `id` and `status` column to verify
# that the SQL Server database is accessible and writable.
module LsaSqlServer
  class DbUp < SqlServerBase
    include ::HmisStructure::Base
    self.table_name = :db_up

    def self.csv_columns
      [
        :id,
        :status,
      ]
    end

    def self.hmis_configuration(*)
      {
        status: {
          type: :string,
        },
      }
    end
  end
end
