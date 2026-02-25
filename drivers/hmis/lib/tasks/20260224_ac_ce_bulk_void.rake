# frozen_string_literal: true

desc 'AC-specific task to bulk void clients from Coordinated Entry'
# rails driver:hmis:ac_ce_bulk_void CLIENT_IDS=1,2,3 CE_PROJECT_ID=456 DRY_RUN=true
# CLIENT_IDS is a comma-separated list of *destination* client IDs. The script finds the corresponding source clients to void.
# CE_PROJECT_ID is the ID of the Coordinated Entry project
# DRY_RUN=true logs the enrollments that would be processed, without taking action
task ac_ce_bulk_void: [:environment] do
  client_ids = ENV.fetch('CLIENT_IDS').split(',').map(&:strip)
  project_id = ENV.fetch('CE_PROJECT_ID')
  dry_run = ENV.fetch('DRY_RUN', 'false') == 'true'
  AcCeBulkVoid.new.perform(destination_client_ids: client_ids, ce_project_id: project_id, dry_run: dry_run)
end

class AcCeBulkVoid
  VOID_REASON_TEXT = 'This household has been exited from Coordinated Entry and removed from the Homeless Housing Program Waitlist as part of the CE Waitlist Management Process due to no contact with Coordinated Entry in at least 45 days.'

  # Hard-coded expectations of the Void Assessment form shape
  VOID_FORM_IDENTIFIER = 'void_assessment'

  def perform(destination_client_ids:, ce_project_id:, dry_run:)
    # Expect the given project ID to be open on the current date, and to be a Coordinated Entry project (14)
    project = Hmis::Hud::Project.open_on_date.where(project_type: 14).find(ce_project_id)
    @data_source_id = project.data_source_id
    @hud_system_user = Hmis::Hud::User.system_user(data_source_id: @data_source_id)
    @current_date = Date.current

    # Find the Void Assessment and validate it has the expected link IDs
    void_definition = Hmis::Form::Definition.published.find_by(identifier: VOID_FORM_IDENTIFIER)

    # Validate the existence of the CDEDs we want to create
    cded_scope = Hmis::Hud::CustomDataElementDefinition.for_type(Hmis::Hud::CustomAssessment.sti_name).where(data_source_id: @data_source_id)
    @void_cded = cded_scope.find_by(key: 'void_assessment_void_all_referrals')
    @void_reason_cded = cded_scope.find_by(key: 'void_assessment_void_reason')

    puts "Bulk voiding #{destination_client_ids.count} destination clients for CE project #{ce_project_id}"

    source_client_ids = Hmis::WarehouseClient.where(destination_id: destination_client_ids).pluck(:source_id)

    # Find open enrollments for the given clients in the CE project
    enrollments = Hmis::Hud::Enrollment.
      open_excluding_wip.
      where(project: project).
      joins(:client).
      where(client: { id: source_client_ids })

    puts "Found #{enrollments.count} enrollments to process"

    if dry_run
      puts "DRY RUN: Would have processed the following enrollments:\n#{enrollments.pluck(:enrollment_id).join("\n")}"
      return
    end

    puts 'Processing enrollments:'

    # Process each enrollment to void the client
    enrollments.find_each do |enrollment|
      process_enrollment(enrollment, void_definition)
    end

    puts 'Completed processing all enrollments'
  end

  private

  def process_enrollment(enrollment, void_definition)
    Hmis::Hud::Base.transaction do
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

      puts enrollment.enrollment_id
    end
  end
end
