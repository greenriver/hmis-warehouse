###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../sql_server_base' unless ENV['NO_LSA_RDS'].present?
require_relative 'lsa_sql_server' unless ENV['NO_LSA_RDS'].present?
module LsaSqlServer
  class LSAReportSummary
    def fetch_summary
      # lsa_Report has no primary key; add_missing_identity_columns gives it a
      # temporary `id` column earlier in the run, ensure we have one here so `.first` works.
      remove_primary_key = false
      if LsaSqlServer::LSAReport.primary_key.blank?
        LsaSqlServer::LSAReport.primary_key = 'id'
        remove_primary_key = true
      end
      rep = LsaSqlServer::LSAReport.first
      report_columns.map do |column, title|
        [
          title,
          rep[column],
        ]
      end.to_h
    ensure
      LsaSqlServer::LSAReport.primary_key = nil if remove_primary_key
    end

    private def report_columns
      {
        UnduplicatedClient: 'Unique count of clients',
        HouseholdEntry: 'Distinct household count',
      }
    end
  end
end
