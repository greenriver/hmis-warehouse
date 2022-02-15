###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
    end
  end
end
