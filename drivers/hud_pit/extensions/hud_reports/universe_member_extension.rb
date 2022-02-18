###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::HudReports
  module UniverseMemberExtension
    extend ActiveSupport::Concern

    included do
      belongs_to(
        :client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudPit::Fy2022::PitClient'))
        end,
        class_name: 'HudPit::Fy2022::PitClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
    end
  end
end
