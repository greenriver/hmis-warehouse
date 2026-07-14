###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Bulk void a list of destination clients from the waitlist and exit them from the Coordinated Entry project.
#
# Usage: HmisExternalApis::AcHmis::BulkVoider.new.perform(destination_client_ids: [1637, 39094], ce_project_id: 201, dry_run: true)
#
# For more useful log output, set the log level to INFO rather than DEBUG, so that we can easily copy and paste the list of enrollment IDs that are processed.
# Rails.logger.level = Logger::INFO
# HmisExternalApis::AcHmis::BulkVoider.new.perform(destination_client_ids: [1637, 39094], ce_project_id: 201, dry_run: true)
# Rails.logger.level = Logger::DEBUG
#
# destination_client_ids: a list of destination client IDs to void
# ce_project_id: the ID of the Coordinated Entry project.
# initiated_by_id: the Hmis::User ID that kicked off the run, for logging and PaperTrail metadata. Optional; if not provided, uses the System User.
# dry_run: if true, logs the enrollments that would be processed, without taking action
#
# Notes:
# - This could re-void an enrollment that’s already voided, or a client that wasn't deemed eligible to begin with.
#   If the client has an enrollment in the CE project, then a Void Assessment will be generated, regardless of whether they are on the waitlist.
# - This will create a Void Assessment for clients that are exited from the CE project.
module HmisExternalApis::AcHmis
  class BulkVoider
    VOID_REASON_TEXT = 'This household has been exited from Coordinated Entry and removed from the Homeless Housing Program Waitlist as part of the CE Waitlist Management Process due to no contact with Coordinated Entry in at least 45 days.'

    # Hard-coded expectations of the Void Assessment form shape
    VOID_FORM_IDENTIFIER = 'void_assessment'
    VOID_CDED_KEY = 'void_assessment_void_all_referrals'
    VOID_REASON_CDED_KEY = 'void_assessment_void_reason'

    def perform(destination_client_ids:, ce_project_id:, initiated_by_id: nil, dry_run: false)
      bulk_void_run_id = SecureRandom.uuid

      # Expect the project to be open on the current date, and to be a Coordinated Entry project (14)
      project = Hmis::Hud::Project.hmis.open_on_date.where(project_type: 14).find(ce_project_id)

      @data_source_id = project.data_source_id
      @hud_system_user = Hmis::Hud::User.system_user(data_source_id: @data_source_id)
      initiated_by_id ||= Hmis::User.system_user.id
      @current_date = Date.current

      # Find the Void Assessment and validate the expected CDEDs exist
      @void_definition = Hmis::Form::Definition.published.where(data_source_id: @data_source_id).find_by!(identifier: VOID_FORM_IDENTIFIER)
      cded_scope = Hmis::Hud::CustomDataElementDefinition.for_type(Hmis::Hud::CustomAssessment.sti_name).where(data_source_id: @data_source_id)
      @void_cded = cded_scope.find_by!(key: VOID_CDED_KEY)
      @void_reason_cded = cded_scope.find_by!(key: VOID_REASON_CDED_KEY)

      Rails.logger.info "Bulk voiding #{destination_client_ids.count} destination clients for CE project #{ce_project_id}"

      source_client_ids = Hmis::WarehouseClient.
        where(data_source_id: @data_source_id, destination_id: destination_client_ids).
        pluck(:source_id)

      # Find open enrollments for the given clients in the CE project
      open_enrollments = Hmis::Hud::Enrollment.
        open_excluding_wip.
        where(project: project).
        joins(:client).
        where(client: { id: source_client_ids })

      source_ids_with_open_enrollment = open_enrollments.distinct.pluck(Arel.sql('client.id'))

      # For clients where we couldn't find an open enrollment, get their most recent exited enrollment
      exited_enrollments = Hmis::Hud::Enrollment.exited.
        where(project: project).
        joins(:client).
        where(client: { id: source_client_ids - source_ids_with_open_enrollment }).
        order(Hmis::Hud::Exit.arel_table[:ExitDate].desc, id: :desc).
        preload(:client).
        to_a.group_by { |enrollment| enrollment.client.id }.
        values.map(&:first)

      # Log client IDs that we won't process because they don't have an open or exited enrollment in the CE project
      source_ids_with_enrollment = source_ids_with_open_enrollment + exited_enrollments.map { |enrollment| enrollment.client.id }
      destination_ids_with_enrollment = Hmis::WarehouseClient.
        where(data_source_id: @data_source_id, source_id: source_ids_with_enrollment, destination_id: destination_client_ids).
        pluck(:destination_id)
      destination_ids_without_enrollment = destination_client_ids.map(&:to_s) - destination_ids_with_enrollment.map(&:to_s)

      Rails.logger.info "Destination client IDs with no enrollment to process (#{destination_ids_without_enrollment.size}): #{destination_ids_without_enrollment.join(', ')}" if destination_ids_without_enrollment.any?

      return if open_enrollments.empty? && exited_enrollments.empty?

      if dry_run
        Rails.logger.info "DRY RUN: Would have exited and voided the following #{open_enrollments.count} open enrollments (and their household members):\n#{open_enrollments.pluck(:enrollment_id).join("\n")}" if open_enrollments.any?
        Rails.logger.info "DRY RUN: Would have voided the following #{exited_enrollments.count} exited enrollments:\n#{exited_enrollments.map(&:enrollment_id).join("\n")}" if exited_enrollments.any?
        return
      end

      # Enrollments to make a void assessment for (clients in the provided list)
      open_enrollment_ids_to_void = open_enrollments.pluck(:id).to_set

      Rails.logger.info "Processing open enrollments (#{open_enrollments.count}) and exited enrollments (#{exited_enrollments.count}):"

      skipped = []

      # Wrap the write-changes in a PaperTrail request that manually sets the user and request ID.
      # This enables us to more easily trace the changes and rollback a bulk void operation if needed.
      PaperTrail.request(
        whodunnit: initiated_by_id,
        controller_info: {
          user_id: initiated_by_id,
          true_user_id: initiated_by_id,
          request_id: bulk_void_run_id,
        },
      ) do
        Hmis::Hud::Base.transaction do
          open_enrollments.preload(household: :enrollments).each do |enrollment|
            # Can't auto-exit incomplete members. Skip entirely and log that we skipped
            if enrollment.household.any_wip?
              skipped << [enrollment.enrollment_id, enrollment.client.warehouse_id]
              next
            end

            enrollment.household.enrollments.open_excluding_wip.each do |e|
              # Create a void assessment only if the client was in the provided list
              create_void_assessment(e) if open_enrollment_ids_to_void.include?(e.id)
              Rails.logger.info e.enrollment_id + (open_enrollment_ids_to_void.include?(e.id) ? '' : " (household member of #{enrollment.enrollment_id})")
            end

            # Exit all household members via shared service (creates exit assessment, releases unit, closes referral)
            Hmis::EnrollmentExitCreator.call(
              enrollment_id: enrollment.id,
              exit_date: @current_date,
              exit_household_members: true,
            )
          end

          exited_enrollments.each do |enrollment|
            # Just create a void assessment for exited enrollments (no need to touch household members)
            create_void_assessment(enrollment)
            Rails.logger.info enrollment.enrollment_id + ' (already exited)'
          end
        end
      end

      if skipped.any?
        Rails.logger.info "Skipped #{skipped.count} enrollments because they have incomplete household members:"
        skipped.each do |enrollment_id, client_id|
          Rails.logger.info "#{enrollment_id} (client #{client_id})"
        end
      end
      Rails.logger.info 'Completed processing all enrollments'
    end

    private

    def create_void_assessment(enrollment)
      if void_assessment_exists?(enrollment)
        Rails.logger.info "Skipped creating a Void Assessment for #{enrollment.enrollment_id} because it is already voided"
        return
      end

      assessment = Hmis::Hud::CustomAssessment.new(
        user: @hud_system_user,
        assessment_date: @current_date,
        data_collection_stage: 99,
        data_source_id: enrollment.data_source_id,
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
        created_by_hud_user: @hud_system_user,
        updated_by_hud_user: @hud_system_user,
        definition: @void_definition,
        wip: false,
      )
      assessment.build_form_processor(definition: @void_definition)
      assessment.save!
      assessment.form_processor.save!

      assessment.custom_data_elements.create!(
        data_element_definition: @void_cded,
        user: @hud_system_user,
        data_source_id: assessment.data_source_id,
        value_boolean: true,
      )
      assessment.custom_data_elements.create!(
        data_element_definition: @void_reason_cded,
        user: @hud_system_user,
        data_source_id: assessment.data_source_id,
        value_string: VOID_REASON_TEXT,
      )
    end

    def void_assessment_exists?(enrollment)
      enrollment.custom_assessments.
        with_form_definition_identifier(VOID_FORM_IDENTIFIER).
        joins(:custom_data_elements).
        merge(Hmis::Hud::CustomDataElement.of_type(@void_cded).where(value_boolean: true)).
        exists?
    end
  end
end
