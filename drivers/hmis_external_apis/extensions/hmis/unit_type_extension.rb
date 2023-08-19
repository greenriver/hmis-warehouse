###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module UnitTypeExtension
      extend ActiveSupport::Concern
      include ExternallyIdentifiedMixin

      included do
        has_many :external_referral_requests, class_name: 'HmisExternalApis::AcHmis::ReferralRequest', dependent: :restrict_with_exception
        has_one :mper_id,
                -> { where(namespace: HmisExternalApis::AcHmis::Mper::SYSTEM_ID) },
                class_name: 'HmisExternalApis::ExternalId',
                as: :source
        has_many :external_unit_availability_syncs, class_name: 'HmisExternalApis::AcHmis::UnitAvailabilitySync', dependent: :destroy
      end

      # @param project_id [Integer]
      # @param user_id [Integer]
      def track_availability(project_id:, user_id:)
        record = {
          project_id: project_id,
          user_id: user_id,
          unit_type_id: id,
        }
        HmisExternalApis::AcHmis::UnitAvailabilitySync.import!(
          [record],
          validate: false,
          on_duplicate_key_update: {
            conflict_target: [:project_id, :unit_type_id],
            columns: 'local_version = local_version + 1',
          },
        )
      end
    end
  end
end
