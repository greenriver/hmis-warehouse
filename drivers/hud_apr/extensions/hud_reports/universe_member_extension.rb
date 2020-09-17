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
    end
  end
end
