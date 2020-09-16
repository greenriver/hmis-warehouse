module HudApr::HudReports
  module UniverseMemberExtension
    extend ActiveSupport::Concern

    included do
      belongs_to :apr_client, -> { where(universe_membership_type: 'HudApr::Fy2020::AprClient') },
                 class_name: 'HudApr::Fy2020::AprClient', foreign_key: :universe_membership_id, inverse_of: :hud_reports_universe_members
    end
  end
end
