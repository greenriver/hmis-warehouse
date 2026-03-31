###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Fy2024
  class Return < HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_returns'
    include Detail

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :exit_enrollment, class_name: 'HudSpmReport::Fy2024::SpmEnrollment'
    belongs_to :return_enrollment, class_name: 'HudSpmReport::Fy2024::SpmEnrollment', optional: true
    has_many :hud_reports_universe_members, inverse_of: :universe_membership,
                                            class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    def self.apply_search_scope(scope) = scope.left_outer_joins(:exit_enrollment, :return_enrollment)
    def self.search_columns = HudSpmReport::Fy2024::SpmEnrollment.search_columns
    def project_id = [exit_enrollment, return_enrollment].detect(&:present?)&.enrollment&.project&.id
    def data_source_id = [exit_enrollment&.enrollment&.data_source_id, return_enrollment&.enrollment&.data_source_id].detect(&:present?)

    def self.detail_headers
      client_columns = ['client_id', 'exit_enrollment.first_name', 'exit_enrollment.last_name', 'exit_enrollment.personal_id']
      hidden_columns = ['id', 'report_instance_id'] + client_columns
      join_columns = ['exit_enrollment.enrollment.project.project_name', 'return_enrollment.enrollment.project.project_name']
      columns = client_columns + (column_names + join_columns - hidden_columns)
      columns.map { |col| [col, header_label(col)] }.to_h
    end
  end
end
