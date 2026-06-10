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
          active_version = ::HudReports::BaseController.new.default_report_version
          enrollment_class_name = "HudSpmReport::#{active_version.to_s.camelize}::SpmEnrollment"
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq(enrollment_class_name))
        end,
        class_name: 'HudSpmReport::Fy2026::SpmEnrollment', # NOTE: this doesn't match, but the SPM enrollments all use the same table, so should be safe
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
      belongs_to(
        :return,
        -> do
          active_version = ::HudReports::BaseController.new.default_report_version
          return_class_name = "HudSpmReport::#{active_version.to_s.camelize}::Return"
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq(return_class_name))
        end,
        class_name: 'HudSpmReport::Fy2026::Return', # NOTE: this doesn't match, but the SPM returns all use the same table, so should be safe
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
        optional: true,
      )
    end
  end
end
