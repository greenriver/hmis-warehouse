###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Bulk void a list of destination clients from the waitlist and exit them from the Coordinated Entry project.
#
# Usage: HmisExternalApis::AcHmis::BulkVoider.new.perform(destination_client_ids: [1637, 39094], ce_project_id: 201, dry_run: true)
#
# destination_client_ids: a list of destination client IDs to void
# ce_project_id: the ID of the Coordinated Entry project
# dry_run: if true, logs the enrollments that would be processed, without taking action
#
# Notes:
# - This could re-void an enrollment that’s already voided, or a client that wasn't deemed eligible to begin with.
#   If the client has an open enrollment in the CE project, then a Void Assessment will be generated, regardless of whether they are on the waitlist.
# - This will *not* void clients that are exited from the CE project, even if they are still on the waitlist.
module HmisExternalApis::AcHmis
  class BulkVoider
    VOID_REASON_TEXT = 'This household has been exited from Coordinated Entry and removed from the Homeless Housing Program Waitlist as part of the CE Waitlist Management Process due to no contact with Coordinated Entry in at least 45 days.'

    # Hard-coded expectations of the Void Assessment form shape
    VOID_FORM_IDENTIFIER = 'void_assessment'

    def perform(destination_client_ids:, ce_project_id:, dry_run: false)
      # Expect the given project ID to be open on the current date, and to be a Coordinated Entry project (14)
      project = Hmis::Hud::Project.hmis.open_on_date.where(project_type: 14).find(ce_project_id)
      @data_source_id = project.data_source_id
      @hud_system_user = Hmis::Hud::User.system_user(data_source_id: @data_source_id)
      @current_date = Date.current

      # Find the Void Assessment and validate it has the expected link IDs
      void_definition = Hmis::Form::Definition.published.find_by(identifier: VOID_FORM_IDENTIFIER)

      # Raise if the expected CDEDs are not found
      cded_scope = Hmis::Hud::CustomDataElementDefinition.for_type(Hmis::Hud::CustomAssessment.sti_name).where(data_source_id: @data_source_id)
      @void_cded = cded_scope.find_by(key: 'void_assessment_void_all_referrals')
      @void_reason_cded = cded_scope.find_by(key: 'void_assessment_void_reason')

      Rails.logger.info "Bulk voiding #{destination_client_ids.count} destination clients for CE project #{ce_project_id}"

      source_client_ids = Hmis::WarehouseClient.where(destination_id: destination_client_ids).pluck(:source_id)

      # Find open enrollments for the given clients in the CE project
      enrollments = Hmis::Hud::Enrollment.
        open_excluding_wip.
        where(project: project).
        joins(:client).
        where(client: { id: source_client_ids })

      # Log client IDs that we won't process because they don't have an open enrollment in the CE project
      source_ids_with_enrollment = enrollments.distinct.pluck(Arel.sql('client.id'))
      destination_ids_with_enrollment = Hmis::WarehouseClient.
        where(source_id: source_ids_with_enrollment, destination_id: destination_client_ids).
        pluck(:destination_id)
      destination_ids_without_enrollment = destination_client_ids.map(&:to_s) - destination_ids_with_enrollment.map(&:to_s)

      Rails.logger.info "Found #{enrollments.count} enrollments to process"
      Rails.logger.info "Destination client IDs with no enrollment to process (#{destination_ids_without_enrollment.size}): #{destination_ids_without_enrollment.join(', ')}" if destination_ids_without_enrollment.any?

      if dry_run
        Rails.logger.info "DRY RUN: Would have processed the following enrollments:\n#{enrollments.pluck(:enrollment_id).join("\n")}"
        return
      end

      Rails.logger.info 'Processing enrollments:'

      Hmis::Hud::Base.transaction do
        # Process each enrollment to void the client
        enrollments.find_each do |enrollment|
          process_enrollment(enrollment, void_definition)
        end
      end

      Rails.logger.info 'Completed processing all enrollments'
    end

    private

    def process_enrollment(enrollment, void_definition)
      # Build a synthetic Void Assessment
      assessment = Hmis::Hud::CustomAssessment.new(
        user: @hud_system_user,
        assessment_date: @current_date,
        data_collection_stage: 99,
        data_source_id: enrollment.data_source_id,
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
        created_by_hud_user: @hud_system_user, # todo @martha - this isn't working
        updated_by_hud_user: @hud_system_user,
        definition: void_definition,
        wip: false,
      )
      assessment.build_form_processor(definition: void_definition)
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

      # Create an Exit record exiting the client from the CE project.
      # TODO - This is copied from Auto Exit Job, and should be refactored to a shared place, that can also be used for bulk-exiting enrollments (#6917)
      exit_record = Hmis::Hud::Exit.new(
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
        data_source_id: enrollment.data_source_id,
        user_id: @hud_system_user.user_id,
        exit_date: @current_date,
        destination: ::HudHelper.util.destination_no_exit_interview_completed,
      )
      exit_assessment = Hmis::Hud::CustomAssessment.new(
        user_id: @hud_system_user.user_id,
        assessment_date: @current_date,
        data_collection_stage: 3,
        data_source_id: enrollment.data_source_id,
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
      )
      exit_assessment.build_form_processor(exit: exit_record)
      raise ActiveRecord::RecordInvalid, exit_record if exit_record.invalid?

      exit_assessment.save!

      Rails.logger.info enrollment.enrollment_id
    end
  end
end
