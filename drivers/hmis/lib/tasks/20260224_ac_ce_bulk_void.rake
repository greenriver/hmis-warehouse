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
  EXPECTED_LINK_IDS = {
    assessment_date: 'assessment_date',
    void_boolean: 'void_all_referrals',
    void_reason: 'void_reason',
  }.freeze

  def perform(destination_client_ids:, ce_project_id:, dry_run:)
    # Expect the given project ID to be open on the current date, and to be a Coordinated Entry project (14)
    project = Hmis::Hud::Project.open_on_date.where(project_type: 14).find(ce_project_id)
    @data_source_id = project.data_source_id
    @hud_system_user = Hmis::Hud::User.system_user(data_source_id: @data_source_id)
    @current_date = Date.current

    # Find the Void Assessment and validate it has the expected link IDs
    void_definition = Hmis::Form::Definition.published.find_by(identifier: VOID_FORM_IDENTIFIER)
    validate_form_definition!(void_definition)

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

  def validate_form_definition!(definition)
    raise "Form definition '#{VOID_FORM_IDENTIFIER}' not found" unless definition

    missing = EXPECTED_LINK_IDS.values.reject { |link_id| definition.link_id_item_hash.key?(link_id) }
    raise "Form '#{definition.identifier}' is missing expected link IDs: #{missing.join(', ')}" if missing.any?
  end

  def process_enrollment(enrollment, void_definition)
    Hmis::Hud::Base.transaction do
      # Create a system-user-generated Void Assessment marking the client as voided
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(
        enrollment: enrollment,
        user: @hud_system_user,
        form_definition: void_definition,
        assessment_date: @current_date,
      )

      link_id_values = {
        EXPECTED_LINK_IDS[:assessment_date] => @current_date.iso8601,
        EXPECTED_LINK_IDS[:void_boolean] => true,
        EXPECTED_LINK_IDS[:void_reason] => VOID_REASON_TEXT,
      }

      assessment.form_processor.assign_attributes(
        values: link_id_values,
        hud_values: build_hud_values(void_definition, link_id_values),
      )
      assessment.form_processor.run!(user: system_user)
      assessment.save_submitted_assessment!(current_user: system_user)

      # Create an Exit record exiting the client from the CE project
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

  def build_hud_values(definition, link_id_values)
    link_id_values.each_with_object({}) do |(link_id, value), accumulator|
      item = definition.link_id_item_hash[link_id]

      key = if item.mapping.custom_field_key.present?
        item.mapping.custom_field_key
      elsif link_id == EXPECTED_LINK_IDS[:assessment_date]
        'assessmentDate'
      else
        raise "Unexpected link ID #{link_id}"
      end

      accumulator[key] = value
    end.compact
  end

  def system_user
    @system_user ||= begin
      user = Hmis::User.system_user
      user.hmis_data_source_id = @data_source_id
      user
    end
  end
end
