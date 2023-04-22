###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module Hud
      module ProjectExtension
        extend ActiveSupport::Concern
        include ExternallyIdentifiedMixin

        included do
          has_many :external_ids, class_name: 'HmisExternalApis::ExternalId', as: :source
          has_many :external_referral_requests, class_name: 'HmisExternalApis::ReferralRequest', dependent: :destroy
          has_many :external_referral_postings, class_name: 'HmisExternalApis::ReferralPosting', dependent: :destroy
        end

        class_methods do
          def order_by_created_at(dir = :asc)
            order(date_created: dir)
          end
        end

      end
    end
  end
end
