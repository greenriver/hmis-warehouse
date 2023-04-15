###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  # A member of a household that is referred for services
  class ReferralHouseholdMember < HmisExternalApisBase
    self.table_name = 'hmis_external_referral_household_members'
    belongs_to :referral, class_name: 'HmisExternalApis::Referral'
    belongs_to :client, class_name: 'Hmis::Hud::Client'
    validates :relationship_to_hoh, inclusion: { in: ::HudLists.relationship_to_ho_h_map.keys }, allow_blank: false
  end
end
