###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::HudReports
  module UniverseMemberExtension
    extend ActiveSupport::Concern

    included do
      belongs_to(
        :spm_client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudSpmReport::Fy2020::SpmClient'))
        end,
        class_name: 'HudSpmReport::Fy2020::SpmClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
      belongs_to(
        :enrollment,
        -> do
          TodoOrDie("Set SPM Default Generator on Staging to 'HudSpmReport::Fy2026::SpmEnrollment'", by: '2025-09-01')
          TodoOrDie("Set SPM Default Generator to 'HudSpmReport::Fy2026::SpmEnrollment'", by: '2025-10-01')
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudSpmReport::Fy2024::SpmEnrollment'))
        end,
        class_name: 'HudSpmReport::Fy2024::SpmEnrollment',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
      belongs_to(
        :return,
        -> do
          TodoOrDie("Set SPM Default Generator on Staging to 'HudSpmReport::Fy2026::Return'", by: '2025-09-01')
          TodoOrDie("Set SPM Default Generator to 'HudSpmReport::Fy2026::Return'", by: '2025-10-01')
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudSpmReport::Fy2024::Return'))
        end,
        class_name: 'HudSpmReport::Fy2024::Return',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
    end
  end
end
