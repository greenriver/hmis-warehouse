###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Fy2020
  class AprClient < ::HudReports::ReportClientBase
    self.table_name = 'hud_report_apr_clients'
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    has_many :hud_report_apr_living_situations, class_name: 'HudApr::Fy2020::AprLivingSituation', foreign_key: :hud_report_apr_client_id, inverse_of: :apr_client
    has_many :hud_report_ce_assessments, class_name: 'HudApr::Fy2020::CeAssessment', foreign_key: :hud_report_apr_client_id, inverse_of: :apr_client
    has_many :hud_report_ce_events, class_name: 'HudApr::Fy2020::CeEvent', foreign_key: :hud_report_apr_client_id, inverse_of: :apr_client
    belongs_to :source_enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true

    # Hide ID, move client_id, and name to the front
    def self.detail_headers
      special = ['client_id', 'first_name', 'last_name']
      remove = ['id', 'created_at', 'updated_at']
      cols = special + (column_names - special - remove)
      cols.map do |h|
        [h, h.humanize]
      end.to_h
    end
  end
end
