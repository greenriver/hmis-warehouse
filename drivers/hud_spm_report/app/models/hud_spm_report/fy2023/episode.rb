###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Fy2023
  class Episode < HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_episodes'
    include Detail

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    has_many :enrollment_links
    has_many :enrollments, through: :enrollment_links
    has_many :hud_reports_universe_members, inverse_of: :universe_membership,
                                            class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    def enrollment = enrollments.first
    def project_id = enrollment&.project_id
    def data_source_id = enrollment&.data_source_id

    def self.apply_search_scope(scope) = scope.joins(:enrollments)
    def self.search_columns = HudSpmReport::Fy2023::SpmEnrollment.search_columns

    def self.detail_headers
      client_columns = ['client_id', 'enrollment.first_name', 'enrollment.last_name', 'enrollment.personal_id']
      hidden_columns = ['id', 'report_instance_id'] + client_columns
      columns = client_columns + (column_names - hidden_columns)
      columns.map { |col| [col, header_label(col)] }.to_h
    end
  end
end
