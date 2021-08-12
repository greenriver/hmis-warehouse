###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::HudReports
  module UniverseMemberExtension
    extend ActiveSupport::Concern

    included do
      belongs_to(
        :apr_client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudApr::Fy2020::AprClient'))
        end,
        class_name: 'HudApr::Fy2020::AprClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
      )

      # duplicate belongs_to to
      belongs_to(
        :hud_report_apr_client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudApr::Fy2020::AprClient'))
        end,
        class_name: 'HudApr::Fy2020::AprClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
      )

      # duplicate belongs_to to
      belongs_to(
        :ce_apr_client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudApr::Fy2020::AprClient'))
        end,
        class_name: 'HudApr::Fy2020::AprClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
      )
    end
  end
end
