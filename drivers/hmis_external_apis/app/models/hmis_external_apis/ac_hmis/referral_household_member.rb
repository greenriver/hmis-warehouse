###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # A member of a household that is referred for services
  class ReferralHouseholdMember < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_referral_household_members'
    belongs_to :referral, class_name: 'HmisExternalApis::AcHmis::Referral'
    belongs_to :client, class_name: 'Hmis::Hud::Client'

    enum(
      relationship_to_hoh: ::HudUtility.hud_list_map_as_enumerable(:relationship_to_ho_h_map)
    )

    def self.where_is_h_oh
      where(relationship_to_hoh: 'self_head_of_household')
    end
  end
end
