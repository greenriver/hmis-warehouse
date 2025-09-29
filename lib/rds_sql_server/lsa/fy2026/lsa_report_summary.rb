###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../sql_server_base' unless ENV['NO_LSA_RDS'].present?
require_relative 'lsa_sql_server' unless ENV['NO_LSA_RDS'].present?
module LsaSqlServer
  class LSAReportSummary
    def fetch_summary
      rep = LsaSqlServer::LSAReport.first
      report_columns.map do |column, title|
        [
          title,
          rep[column],
        ]
      end.to_h
    end

    private def report_columns
      {
        UnduplicatedClient: 'Unique count of clients',
        HouseholdEntry: 'Distinct household count',
      }
    end
  end
end
