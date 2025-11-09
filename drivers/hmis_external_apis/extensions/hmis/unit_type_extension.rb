###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis
  module Hmis
    module UnitTypeExtension
      extend ActiveSupport::Concern
      include HmisExternalApis::ExternallyIdentifiedMixin

      included do
        has_many :external_referral_requests, class_name: 'HmisExternalApis::AcHmis::ReferralRequest', dependent: :restrict_with_exception
        has_one :mper_id,
                -> { where(namespace: HmisExternalApis::AcHmis::Mper::SYSTEM_ID) },
                class_name: 'HmisExternalApis::ExternalId',
                as: :source
      end
    end
  end
end
