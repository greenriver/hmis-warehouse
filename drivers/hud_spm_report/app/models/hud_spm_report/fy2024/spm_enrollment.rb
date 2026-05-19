###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Fy2024
  class SpmEnrollment < HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_enrollments'
    include Detail
    include HasPiiAttributes
    pii_attr :first_name
    pii_attr :last_name
    pii_attr :age

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'
    has_many :hud_reports_universe_members, inverse_of: :universe_membership,
                                            class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    def self.detail_headers
      client_columns = ['client_id', 'first_name', 'last_name', 'personal_id', 'data_source_id']
      hidden_columns = [
        'id', 'report_instance_id', 'previous_income_benefits_id',
        'current_income_benefits_id', 'enrollment_id'
      ] + client_columns
      columns = client_columns + (column_names - hidden_columns)
      columns.map { |col| [col, header_label(col)] }.to_h
    end

    def self.search_columns
      t = arel_table
      [
        t[:first_name], t[:last_name], t[:personal_id],
        Arel::Nodes::NamedFunction.new('CAST', [t[:client_id].as('TEXT')])
      ]
    end
  end
end
