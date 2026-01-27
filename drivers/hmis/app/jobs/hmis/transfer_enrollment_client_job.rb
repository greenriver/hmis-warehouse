###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class TransferEnrollmentClientJob < BaseJob
    # Utility class for transferring an Enrollment from one Client to another.
    # Updates all associated records' PersonalIDs to point to the new client.
    # Without updating timestamps on associated records or leaving a papertrail.
    #
    # This can be used for:
    # - Manual enrollment transfers (admin feature)
    # - Un-merging clients (restoring enrollments to original clients)
    #
    # Usage:
    #   Hmis::TransferEnrollmentClientJob.perform_now(enrollment_id: enrollment.id, to_client_id: new_client.id, dry_run: true)
    #
    # NOTE: This job intentionally uses update_column/update_all so it can update PersonalID references
    # without updating timestamps on associated records or leaving a papertrail.
    def perform(enrollment_id:, to_client_id:, dry_run: false)
      enrollment = Hmis::Hud::Enrollment.find_by(id: enrollment_id)
      raise ArgumentError, 'Enrollment must be provided' unless enrollment

      to_client = Hmis::Hud::Client.find_by(id: to_client_id)
      raise ArgumentError, 'To client must be provided' unless to_client

      from_client = enrollment.client
      raise ArgumentError, 'Could not find existing client for enrollment' unless from_client

      raise ArgumentError, 'Clients must be in the same data source' unless from_client.data_source_id == to_client.data_source_id
      raise ArgumentError, 'Enrollment must be in the same data source as to_client' unless enrollment.data_source_id == to_client.data_source_id

      if dry_run
        update_personal_ids(enrollment: enrollment, from_client: from_client, to_client: to_client, dry_run: true)
        Rails.logger.info('Dry run complete')
        return
      end

      Hmis::Hud::Base.transaction do
        update_personal_ids(enrollment: enrollment, from_client: from_client, to_client: to_client, dry_run: false)
        enrollment.invalidate_processing!
      end

      # Queue service history processing (if not already queued)
      Hmis::Hud::Enrollment.queue_service_history_processing!

      Rails.logger.info 'Completed successfully'
    end

    private

    def update_personal_ids(enrollment:, from_client:, to_client:, dry_run:)
      enrollment_id = enrollment.EnrollmentID

      if dry_run
        Rails.logger.info "Dry run: would update Enrollment #{enrollment.id} PersonalID from #{from_client.personal_id} to #{to_client.personal_id} (EnrollmentID: #{enrollment_id})"
      else
        enrollment.update_column(:PersonalID, to_client.personal_id)
        Rails.logger.info "Transferred Enrollment #{enrollment.id} from Client #{from_client.id} (PersonalID: #{from_client.personal_id}) to Client #{to_client.id} (PersonalID: #{to_client.personal_id})"
      end

      # Update PersonalID references on associated records
      enrollment_scope = Hmis::Hud::Enrollment.where(id: enrollment.id)
      HmisDataCleanup::Util.fix_incorrect_personal_id_references!(enrollment_scope: enrollment_scope, dry_run: dry_run)
    end
  end
end
