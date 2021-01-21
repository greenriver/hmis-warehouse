module HudDataQualityReport::HudReports
  module UniverseMemberExtension
    extend ActiveSupport::Concern

    included do
      belongs_to(
        :dq_client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudDataQualityReport::Fy2020::DqClient'))
        end,
        class_name: 'HudDataQualityReport::Fy2020::DqClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
      )

      # duplicate belongs_to
      belongs_to(
        :hud_report_dq_client,
        -> do
          where(HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HudDataQualityReport::Fy2020::DqClient'))
        end,
        class_name: 'HudDataQualityReport::Fy2020::DqClient',
        foreign_key: :universe_membership_id,
        inverse_of: :hud_reports_universe_members,
      )
    end
  end
end
