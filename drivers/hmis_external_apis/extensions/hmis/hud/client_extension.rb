###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module Hud
      module ClientExtension
        extend ActiveSupport::Concern
        included do
          has_many :external_ids, class_name: 'HmisExternalApis::ExternalId', as: :source
          has_many :external_referral_household_members, class_name: 'HmisExternalApis::ReferralHouseholdMember', dependent: :destroy, inverse_of: :client
        end

        def external_ids_by_slug(slug)
          external_ids.joins(:remote_credential).where(remote_credential: { slug: slug })
        end
      end
    end
  end
end
