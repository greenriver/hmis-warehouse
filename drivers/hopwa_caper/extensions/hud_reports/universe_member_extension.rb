###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::HudReports
  module UniverseMemberExtension
    extend ActiveSupport::Concern

    included do
      belongs_to(
        :hopwa_caper_service,
        -> do
          where(::HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HopwaCaper::Service'))
        end,
        class_name: 'HopwaCaper::Service',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )

      belongs_to(
        :hopwa_caper_enrollment,
        -> do
          where(::HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HopwaCaper::Enrollment'))
        end,
        class_name: 'HopwaCaper::Enrollment',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
    end
  end
end
