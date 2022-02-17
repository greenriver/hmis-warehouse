###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::HudReports
  module UniverseMemberExtension
    extend ActiveSupport::Concern

    included do
      belongs_to(
        :organization,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudHic::Fy2021::Organization'))
        end,
        class_name: 'HudHic::Fy2021::Organization',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )

      belongs_to(
        :project,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudHic::Fy2021::Project'))
        end,
        class_name: 'HudHic::Fy2021::Project',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )

      belongs_to(
        :inventory,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudHic::Fy2021::Inventory'))
        end,
        class_name: 'HudHic::Fy2021::Inventory',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )

      belongs_to(
        :project_coc,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudHic::Fy2021::ProjectCoc'))
        end,
        class_name: 'HudHic::Fy2021::ProjectCoc',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )

      belongs_to(
        :funder,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudHic::Fy2021::Funder'))
        end,
        class_name: 'HudHic::Fy2021::Funder',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
    end
  end
end
