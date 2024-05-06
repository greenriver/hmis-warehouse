###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
        has_many :external_unit_availability_syncs, class_name: 'HmisExternalApis::AcHmis::UnitAvailabilitySync', dependent: :destroy
      end

      # @param project_id [Integer] Hmis::Hud::Project.id
      # @param user_id [Integer] Hmis::User.id
      def track_availability(project_id:, user_id:)
        return unless HmisEnforcement.hmis_enabled? && HmisExternalApis::AcHmis::Mper.enabled? && mper_id

        # Skip if ProjectID is UUID, which means that this was a project created within the HMIS.
        return if ::Hmis::Hud::Project.find(project_id).project_id.size == 32

        HmisExternalApis::AcHmis::UnitAvailabilitySync.upsert_or_bump_version(
          project_id: project_id,
          user_id: user_id,
          unit_type_id: id,
        )

        # Don't re-queue if job is already queued
        return if Delayed::Job.queued?('HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob')

        HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.
          set(wait: 1.minute). # short wait to accumulate batch of changes before update
          perform_later
      end
    end
  end
end
