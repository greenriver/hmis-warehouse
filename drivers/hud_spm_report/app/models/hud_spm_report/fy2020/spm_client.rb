###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2020
  class SpmClient < ::HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_clients'
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    def self.header_label(col)
      case col.to_s
      when 'source_client_personal_ids'
        'HMIS Personal IDs'
      else
        human_attribute_name(col)
      end
    end
  end
end
