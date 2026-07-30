###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

##
# Utility for building the PH housing CE workflow templates
#
# WARNING! Running this builder will delete existing referrals associated with the housing_workflow template.
# Not intended for repeated use in production.
#
# Pattern: destroy-and-recreate (preferred). See ../README_FOR_CE_WORKFLOW_BUILDERS.md.
module CeWorkflows::Ph
  class HousingWorkflowBuilder
    HOUSING_WORKFLOW_FORMS = {
      # Housing referral workflow.
      # A step that can be revisited after a decline is sent back is modeled as two different nodes sharing one form definition.
      # Both attempts collect the same link IDs. See the note on gateway conditions below.
      # The same is true of the four Review Decline steps, which all share one form.
      housing_coc_initial_review: 'housing_workflow_coc_initial_review',
      housing_shelter_agency_review: 'housing_workflow_shelter_agency_initial_review',
      housing_case_manager_initial_review: 'housing_workflow_case_manager_initial_review',
      housing_case_manager_decision: 'housing_workflow_case_manager_decision',
      housing_cori_hearing: 'housing_workflow_cori_hearing',
      housing_date_housed: 'housing_workflow_date_housed',
      housing_confirm_success: 'housing_workflow_confirm_success',
      housing_review_decline: 'housing_workflow_coc_review_decline',
      housing_review_decline_final: 'housing_workflow_coc_review_decline_final',
      housing_coc_decline: 'housing_workflow_coc_decline',
    }.freeze

    DECLINE_REASON_LINK_ID = Hmis::Ce::ReferralMessageHandler::DECLINE_REASON_LINK_ID

    def initialize(data_source, unsafe_run_in_production: false)
      @data_source = data_source
      @unsafe_run_in_production = unsafe_run_in_production
      raise 'This class destroys data and should not be run in production' if Rails.env.production? && !@unsafe_run_in_production

      @form_definitions = Hmis::Form::Definition.
        in_data_source(@data_source.id).
        where(role: 'CE_REFERRAL_STEP', identifier: HOUSING_WORKFLOW_FORMS.values).
        order(:version).
        index_by(&:identifier)

      missing = HOUSING_WORKFLOW_FORMS.values - @form_definitions.keys
      raise "Missing CE_REFERRAL_STEP forms: #{missing.join(', ')}. Did you run 'rails driver:hmis:seed_definitions'?" if missing.any?
    end

    # TODO @martha: temporary. Seeds every code the forms collect so the template validates while the
    # housing forms are still in flux. Decline reasons should be a curated list, not derived from forms.
    def ensure_decline_reasons
      HOUSING_WORKFLOW_FORMS.values.filter_map { |identifier| @form_definitions[identifier] }.each_with_object({}) do |form, options|
        item = form.link_id_item_hash[DECLINE_REASON_LINK_ID]
        next if item.blank?

        item['pick_list_options']&.each { |option| options[option['code']] ||= option['label'] }
      end.each do |code, label|
        Hmis::Ce::ReferralDeclineReason.find_or_create_by!(
          key: code,
          data_source: @data_source,
        ) { |reason| reason.name = label }
      end
    end

    def build_housing_workflow
      identifier = 'housing_workflow'
      template_name = 'Housing Referral Workflow'

      unless @unsafe_run_in_production
        CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(
          identifier,
          data_source: @data_source,
          delete_opportunities: false,
        )
      end

      template = CeWorkflows::Shared::CeBuilderUtils.create_template(identifier, template_name, @data_source)
      build_housing_graph(template)
      template.validate!
      template
    end

    def build_high_impact_workflow
      # TODO(#9402)
    end

    private

    # Builds the Housing waitlist referral workflow graph on a fresh template.
    #
    # A referral moves through review by the CoC, the shelter agency, and the housing case manager. Any of
    # those steps can decline, which routes to a Review Decline step where the CoC approves the decline,
    # sends the referral back for a second attempt, or overrides and advances. A second decline goes to
    # Final Review Decline, where the CoC either approves the decline or overrides and advances
    # (can't send back a second time).
    #
    # A step and its second attempt are separate nodes sharing one form definition, so they collect the same
    # link IDs, and the four Review Decline steps do too. Gateway conditions are evaluated against the
    # submitted values of *every* completed step in the instance, merged in graph-walk order, so by the time
    # a gateway is reached the most recently visited step's answers are the ones that count. This graph is
    # acyclic and each reused form is only ever revisited further along the graph, so a condition always
    # sees the attempt it belongs to. See Hmis::WorkflowExecution::Engine#all_submitted_values.
    def build_housing_graph(template)
      coc_swimlane = template.swimlanes.create!(name: 'CoC Contacts')
      shelter_agency_swimlane = template.swimlanes.create!(name: 'Shelter Agency')
      case_manager_swimlane = template.swimlanes.create!(name: 'Housing Case Manager')

      # Statuses. 'in_progress' mirrors a referral state machine state, so it is created by
      # CeBuilderUtils.create_state_machine_custom_statuses rather than here.
      in_progress_status = Hmis::Ce::CustomReferralStatus.find_by!(key: 'in_progress', data_source: @data_source)
      pending_decline_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'pending_decline',
        data_source: @data_source,
      ) { |s| s.name = 'Pending Decline' }
      enrolled_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'enrolled',
        data_source: @data_source,
      ) { |s| s.name = 'Enrolled' }

      status_trigger = ->(status) { { event: 'enable_step', message: 'set_custom_referral_status', params: { custom_status_key: status.key } } }
      in_progress = status_trigger.call(in_progress_status)
      pending_decline = status_trigger.call(pending_decline_status)
      enrolled = status_trigger.call(enrolled_status)

      # Only forms that collect their decline reason on a 'decline_reason' item can set it on the referral,
      # so this trigger is only present on those steps. The rest record their reason as a custom field only.
      set_decline_reason = { event: 'complete_step', message: 'set_referral_decline_reason' }
      # A referral that was sent back is active again, so it should no longer carry the decline reason
      # recorded by the step that declined it.
      clear_decline_reason = { event: 'enable_step', message: 'clear_referral_decline_reason' }

      # Events
      start_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_start_event(template)
      accept_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_accept_event(template, update_ce_event: true)
      decline_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_decline_event(template)

      # User tasks
      coc_initial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'CoC Initial Review',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_coc_initial_review),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [in_progress, set_decline_reason],
      )
      shelter_agency_review_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Shelter Agency Initial Review',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_shelter_agency_review),
        template: template,
        swimlane: shelter_agency_swimlane,
        trigger_config: [in_progress],
      )
      shelter_agency_review_2_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Shelter Agency Initial Review (Second Attempt)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_shelter_agency_review),
        template: template,
        swimlane: shelter_agency_swimlane,
        trigger_config: [in_progress, clear_decline_reason],
      )
      schedule_intake_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Housing Case Manager Initial Review & Schedule Intake',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_case_manager_initial_review),
        template: template,
        swimlane: case_manager_swimlane,
        trigger_config: [in_progress],
      )
      schedule_intake_2_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Housing Case Manager Initial Review & Schedule Intake (Second Attempt)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_case_manager_initial_review),
        template: template,
        swimlane: case_manager_swimlane,
        trigger_config: [in_progress, clear_decline_reason],
      )
      case_manager_decision_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Housing Case Manager Decision',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_case_manager_decision),
        template: template,
        swimlane: case_manager_swimlane,
        trigger_config: [in_progress, set_decline_reason],
      )
      case_manager_decision_2_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Housing Case Manager Decision (Second Attempt)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_case_manager_decision),
        template: template,
        swimlane: case_manager_swimlane,
        trigger_config: [in_progress, clear_decline_reason, set_decline_reason],
      )
      cori_hearing_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'CORI Hearing',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_cori_hearing),
        template: template,
        swimlane: case_manager_swimlane,
        trigger_config: [in_progress, set_decline_reason],
      )
      cori_hearing_2_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'CORI Hearing (Second Attempt)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_cori_hearing),
        template: template,
        swimlane: case_manager_swimlane,
        trigger_config: [in_progress, clear_decline_reason, set_decline_reason],
      )
      date_housed_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Indicate Date Client Was Housed',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_date_housed),
        template: template,
        swimlane: case_manager_swimlane,
        trigger_config: [enrolled, { event: 'complete_step', message: 'set_move_in_date' }],
      )
      confirm_success_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Confirm Success',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_confirm_success),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [enrolled],
      )
      review_decline_1_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Review Decline (Shelter Agency)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_review_decline),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [pending_decline],
      )
      review_decline_2_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Review Decline (Case Manager Intake)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_review_decline),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [pending_decline],
      )
      review_decline_3_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Review Decline (Case Manager Decision)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_review_decline),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [pending_decline],
      )
      review_decline_4_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Review Decline (CORI Hearing)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_review_decline),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [pending_decline],
      )
      final_review_decline_1_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Final Review Decline (Shelter Agency)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_review_decline_final),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [pending_decline],
      )
      final_review_decline_2_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Final Review Decline (Case Manager Intake)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_review_decline_final),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [pending_decline],
      )
      final_review_decline_3_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Final Review Decline (Case Manager Decision)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_review_decline_final),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [pending_decline],
      )
      final_review_decline_4_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Final Review Decline (CORI Hearing)',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_review_decline_final),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [pending_decline],
      )
      optional_decline_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Decline Referral',
        form_definition_identifier: HOUSING_WORKFLOW_FORMS.fetch(:housing_coc_decline),
        template: template,
        swimlane: coc_swimlane,
        trigger_config: [set_decline_reason],
      )

      # Script tasks
      create_ce_event_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Generate CE Event',
        template: template,
        trigger_config: [{ event: 'complete_step', message: 'create_ce_event' }],
      )
      create_enrollment_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create Enrollment',
        template: template,
        trigger_config: [
          { event: 'complete_step', message: 'clear_referral_decline_reason' },
          { event: 'complete_step', message: 'create_enrollment' },
        ],
      )
      delete_enrollment_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Delete Enrollment',
        template: template,
        trigger_config: [{ event: 'complete_step', message: 'delete_wip_enrollment' }],
      )
      client_rejected_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Update CE Event with result "Unsuccessful referral: client rejected"',
        template: template,
        trigger_config: [{ event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: '2' } }],
      )
      provider_rejected_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Update CE Event with result "Unsuccessful referral: provider rejected"',
        template: template,
        trigger_config: [{ event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: '3' } }],
      )

      # Shared exit for every decline.
      decline_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'decline')
      decline_gateway.connect_to!(client_rejected_task, condition: 'referral_result = 2')
      decline_gateway.connect_to!(provider_rejected_task, condition: 'referral_result = 3')
      decline_gateway.connect_to!(decline_event)
      client_rejected_task.connect_to!(decline_event)
      provider_rejected_task.connect_to!(decline_event)

      # Start Referral => CoC Initial Review => Generate CE Event (or decline)
      start_event.connect_to!(coc_initial_review_task)
      coc_initial_review_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'coc_initial_review')
      coc_initial_review_task.connect_to!(coc_initial_review_gateway)
      coc_initial_review_gateway.connect_to!(decline_gateway, condition: "coc_initial_review_decision = 'decline'")
      coc_initial_review_gateway.connect_to!(create_ce_event_task)

      # Generate CE Event => Shelter Agency Initial Review, and enable the optional decline task alongside it.
      create_ce_event_task.connect_to!(shelter_agency_review_task)
      create_ce_event_task.connect_to!(optional_decline_task)
      optional_decline_task.connect_to!(delete_enrollment_task)
      delete_enrollment_task.connect_to!(decline_gateway)

      # Shelter Agency Initial Review => Schedule Intake (or decline review).
      shelter_agency_review_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'shelter_agency_review')
      shelter_agency_review_task.connect_to!(shelter_agency_review_gateway)
      shelter_agency_review_gateway.connect_to!(review_decline_1_task, condition: "shelter_agency_decision != 'continue'")
      shelter_agency_review_gateway.connect_to!(schedule_intake_task)

      # Review Decline (Shelter Agency) => approve, send back for a second attempt, or override and advance.
      review_decline_1_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'review_decline_1')
      review_decline_1_task.connect_to!(review_decline_1_gateway)
      review_decline_1_gateway.connect_to!(decline_gateway, condition: "review_decline_decision = 'approve_decline'")
      review_decline_1_gateway.connect_to!(shelter_agency_review_2_task, condition: "review_decline_decision = 'go_back'")
      review_decline_1_gateway.connect_to!(schedule_intake_task)

      # Shelter Agency Initial Review (Second Attempt) => Schedule Intake (or final decline review)
      shelter_agency_review_2_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'shelter_agency_review_2')
      shelter_agency_review_2_task.connect_to!(shelter_agency_review_2_gateway)
      shelter_agency_review_2_gateway.connect_to!(final_review_decline_1_task, condition: "shelter_agency_decision != 'continue'")
      shelter_agency_review_2_gateway.connect_to!(schedule_intake_task)

      final_review_decline_1_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'final_review_decline_1')
      final_review_decline_1_task.connect_to!(final_review_decline_1_gateway)
      final_review_decline_1_gateway.connect_to!(decline_gateway, condition: "review_decline_final_decision = 'approve_decline'")
      final_review_decline_1_gateway.connect_to!(schedule_intake_task)

      # Schedule Intake => Housing Case Manager Decision (or decline review)
      schedule_intake_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'schedule_intake')
      schedule_intake_task.connect_to!(schedule_intake_gateway)
      schedule_intake_gateway.connect_to!(review_decline_2_task, condition: "case_manager_initial_review_decision = 'decline'")
      schedule_intake_gateway.connect_to!(case_manager_decision_task)

      # Review Decline (Case Manager Intake) => approve, send back for a second attempt, or override and advance.
      review_decline_2_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'review_decline_2')
      review_decline_2_task.connect_to!(review_decline_2_gateway)
      review_decline_2_gateway.connect_to!(decline_gateway, condition: "review_decline_decision = 'approve_decline'")
      review_decline_2_gateway.connect_to!(schedule_intake_2_task, condition: "review_decline_decision = 'go_back'")
      review_decline_2_gateway.connect_to!(case_manager_decision_task)

      # Schedule Intake (Second Attempt) => Housing Case Manager Decision (or final decline review)
      schedule_intake_2_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'schedule_intake_2')
      schedule_intake_2_task.connect_to!(schedule_intake_2_gateway)
      schedule_intake_2_gateway.connect_to!(final_review_decline_2_task, condition: "case_manager_initial_review_decision = 'decline'")
      schedule_intake_2_gateway.connect_to!(case_manager_decision_task)

      final_review_decline_2_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'final_review_decline_2')
      final_review_decline_2_task.connect_to!(final_review_decline_2_gateway)
      final_review_decline_2_gateway.connect_to!(decline_gateway, condition: "review_decline_final_decision = 'approve_decline'")
      final_review_decline_2_gateway.connect_to!(case_manager_decision_task)

      # Housing Case Manager Decision => CORI Hearing, Create Enrollment, or decline review
      case_manager_decision_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'case_manager_decision')
      case_manager_decision_task.connect_to!(case_manager_decision_gateway)
      case_manager_decision_gateway.connect_to!(review_decline_3_task, condition: "case_manager_decision = 'decline'")
      case_manager_decision_gateway.connect_to!(cori_hearing_task, condition: "cori_hearing_needed = 'yes'")
      case_manager_decision_gateway.connect_to!(create_enrollment_task)

      # Review Decline (Case Manager Decision) => approve, send back for a second attempt, or override and advance.
      review_decline_3_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'review_decline_3')
      review_decline_3_task.connect_to!(review_decline_3_gateway)
      review_decline_3_gateway.connect_to!(decline_gateway, condition: "review_decline_decision = 'approve_decline'")
      review_decline_3_gateway.connect_to!(case_manager_decision_2_task, condition: "review_decline_decision = 'go_back'")
      review_decline_3_gateway.connect_to!(create_enrollment_task)

      # Housing Case Manager Decision (Second Attempt) => CORI Hearing, Create Enrollment, or final decline review
      case_manager_decision_2_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'case_manager_decision_2')
      case_manager_decision_2_task.connect_to!(case_manager_decision_2_gateway)
      case_manager_decision_2_gateway.connect_to!(final_review_decline_3_task, condition: "case_manager_decision = 'decline'")
      case_manager_decision_2_gateway.connect_to!(cori_hearing_task, condition: "cori_hearing_needed = 'yes'")
      case_manager_decision_2_gateway.connect_to!(create_enrollment_task)

      final_review_decline_3_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'final_review_decline_3')
      final_review_decline_3_task.connect_to!(final_review_decline_3_gateway)
      final_review_decline_3_gateway.connect_to!(decline_gateway, condition: "review_decline_final_decision = 'approve_decline'")
      final_review_decline_3_gateway.connect_to!(create_enrollment_task)

      # CORI Hearing => Create Enrollment (or decline review)
      cori_hearing_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'cori_hearing')
      cori_hearing_task.connect_to!(cori_hearing_gateway)
      cori_hearing_gateway.connect_to!(review_decline_4_task, condition: "cori_hearing_decision = 'decline'")
      cori_hearing_gateway.connect_to!(create_enrollment_task)

      # Review Decline (CORI Hearing) => approve, send back for a second attempt, or override and advance.
      review_decline_4_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'review_decline_4')
      review_decline_4_task.connect_to!(review_decline_4_gateway)
      review_decline_4_gateway.connect_to!(decline_gateway, condition: "review_decline_decision = 'approve_decline'")
      review_decline_4_gateway.connect_to!(cori_hearing_2_task, condition: "review_decline_decision = 'go_back'")
      review_decline_4_gateway.connect_to!(create_enrollment_task)

      # CORI Hearing (Second Attempt) => Create Enrollment (or final decline review)
      cori_hearing_2_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'cori_hearing_2')
      cori_hearing_2_task.connect_to!(cori_hearing_2_gateway)
      cori_hearing_2_gateway.connect_to!(final_review_decline_4_task, condition: "cori_hearing_decision = 'decline'")
      cori_hearing_2_gateway.connect_to!(create_enrollment_task)

      final_review_decline_4_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'final_review_decline_4')
      final_review_decline_4_task.connect_to!(final_review_decline_4_gateway)
      final_review_decline_4_gateway.connect_to!(decline_gateway, condition: "review_decline_final_decision = 'approve_decline'")
      final_review_decline_4_gateway.connect_to!(create_enrollment_task)

      # Create Enrollment => Date Housed => Confirm Success => accept.
      create_enrollment_task.connect_to!(date_housed_task)
      date_housed_task.connect_to!(confirm_success_task)
      confirm_success_task.connect_to!(accept_event)
    end
  end
end
