###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Fy2020
  class AprClient < ::HudReports::ReportClientBase
    self.table_name = 'hud_report_apr_clients'
    acts_as_paranoid

    include HasPiiAttributes
    pii_attr(:ssn)
    pii_attr(:first_name)
    pii_attr(:last_name)
    pii_attr(:dob)
    pii_attr(:age)

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    has_many :hud_report_apr_living_situations, class_name: 'HudApr::Fy2020::AprLivingSituation', foreign_key: :hud_report_apr_client_id, inverse_of: :apr_client
    has_many :hud_report_ce_assessments, class_name: 'HudApr::Fy2020::CeAssessment', foreign_key: :hud_report_apr_client_id, inverse_of: :apr_client
    has_many :hud_report_ce_events, class_name: 'HudApr::Fy2020::CeEvent', foreign_key: :hud_report_apr_client_id, inverse_of: :apr_client
    belongs_to :source_enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true

    # Hide ID, move destination_client_id, and name to the front
    def self.detail_headers
      special = ['destination_client_id', 'personal_id', 'first_name', 'last_name']
      remove = ['id', 'created_at', 'updated_at']
      cols = special + (column_names - special - remove)
      cols.map do |h|
        label = case h
        when 'destination_client_id'
          'Warehouse Client ID'
        when 'client_id'
          'Warehouse Source Client ID'
        when 'personal_id'
          'HMIS Personal ID'
        else
          h.humanize
        end
        [h, label]
      end.to_h
    end

    def self.detail_headers_for_export
      return detail_headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      detail_headers.except('first_name', 'last_name', 'dob', 'ssn')
    end

    def display_value(col, pii_policy:, include_content_tag: true)
      super
    end
  end
end
