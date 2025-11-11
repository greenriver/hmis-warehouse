###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  module Util
    # Utility class for transferring an Enrollment from one Client to another.
    # Updates all associated records' PersonalIDs to point to the new client.
    #
    # This can be used for:
    # - Manual enrollment transfers (admin feature)
    # - Un-merging clients (restoring enrollments to original clients)
    #
    # Usage:
    #   Hmis::Util::TransferEnrollment.new(
    #     enrollment: enrollment,
    #     to_client: new_client,
    #   ).transfer!
    class TransferEnrollment
      attr_reader :enrollment, :from_client, :to_client, :data_source_id

      def initialize(enrollment:, to_client:)
        @enrollment = enrollment
        @from_client = enrollment.client
        @to_client = to_client
        @data_source_id = to_client.data_source_id

        validate!
      end

      def transfer!
        Hmis::Hud::Enrollment.transaction do
          update_enrollment_personal_id
          update_associated_records_personal_ids
        end
      end

      private

      def validate!
        raise ArgumentError, 'Enrollment must be provided' unless enrollment
        raise ArgumentError, 'To client must be provided' unless to_client
        raise ArgumentError, 'Could not find existing client for enrollment' unless from_client
        raise ArgumentError, 'Clients must be in the same data source' unless from_client.data_source_id == to_client.data_source_id
        raise ArgumentError, 'Enrollment must be in the same data source as to_client' unless enrollment.data_source_id == data_source_id
      end

      def update_enrollment_personal_id
        enrollment.update_column(:PersonalID, to_client.personal_id)
        Rails.logger.info "Transferred Enrollment #{enrollment.id} from Client #{from_client.id} (PersonalID: #{from_client.personal_id}) to Client #{to_client.id} (PersonalID: #{to_client.personal_id})"
      end

      def update_associated_records_personal_ids
        # All record types that reference PersonalID and are associated with enrollments
        record_types = [
          Hmis::Hud::Assessment,
          Hmis::Hud::AssessmentQuestion,
          Hmis::Hud::AssessmentResult,
          Hmis::Hud::CurrentLivingSituation,
          Hmis::Hud::CustomAssessment,
          Hmis::Hud::CustomCaseNote,
          Hmis::Hud::CustomService,
          Hmis::Hud::Disability,
          Hmis::Hud::EmploymentEducation,
          Hmis::Hud::Event,
          Hmis::Hud::Exit,
          Hmis::Hud::HealthAndDv,
          Hmis::Hud::IncomeBenefit,
          Hmis::Hud::Service,
          Hmis::Hud::YouthEducationStatus,
        ]

        enrollment_id = enrollment.EnrollmentID

        record_types.each do |record_type|
          t = record_type.arel_table
          scope = record_type.
            where(t['EnrollmentID'].eq(enrollment_id)).
            where(t['PersonalID'].eq(from_client.personal_id)).
            where(t['data_source_id'].eq(data_source_id))

          count = scope.update_all(PersonalID: to_client.personal_id)
          Rails.logger.info "Updated #{count} #{record_type.name} records for Enrollment #{enrollment_id}" if count > 0
        end
      end
    end
  end
end

