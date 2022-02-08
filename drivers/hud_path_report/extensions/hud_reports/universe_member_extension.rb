###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::HudReports
  module UniverseMemberExtension
    extend ActiveSupport::Concern

    included do
      belongs_to(
        :path_client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudPathReport::Fy2020::PathClient'))
        end,
        class_name: 'HudPathReport::Fy2020::PathClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )

      # duplicate belongs_to
      belongs_to(
        :hud_report_path_client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudPathReport::Fy2020::PathClient'))
        end,
        class_name: 'HudPathReport::Fy2020::PathClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
    end
  end
end
