###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Utility for building CE workflow definitions specific to the Az installation.
#
# Business rules worth knowing before changing this:
# - The HUD CE Event referral result on a decline is driven by the *reason* the provider picks, not
#   by the Declined vs Cancelled decision. Any "Client Refused" reason reports client rejected (2);
#   every other reason reports provider rejected (3). See DECLINE_REASONS.
# - The Acknowledgement and Decision forms each offer two reason pick lists, Declined Reason and
#   Cancelled Reason, so the provider only ever sees the reasons valid for the decision they made.
#   set_referral_decline_reason reads a single hardcoded link ID, so each form also carries a hidden
#   `decline_reason` item that autofills from whichever list was answered. That hidden item needs a
#   `mapping` so the frontend includes it in valuesByLinkId (createValuesForSubmit drops unmapped
#   items). Gateways route on `cancelled_reason` directly rather than on the autofilled value.
# - A referral reaches Accepted once Post Referral Review is submitted, regardless of the 'successful'
#   answer. Provider Decision = Accepted creates an incomplete enrollment in the receiving project and
#   closes the CE Event as successful (1); acceptance already happened at that point, so Post Referral
#   Review's 'successful' field only tracks post-acceptance problems and never gates referral status.
# - Declined and Canceled are distinct terminal statuses. Canceled is applied by a trigger that runs
#   *after* reject_referral, which sets the state-machine derived 'rejected' status, so the trigger
#   order on that end event matters.
#
# WARNING! Building this workflow deletes existing referrals associated with the template. Should not
# be re-run in production after initial setup.
#
# Pattern: destroy-and-recreate (preferred)
# @see docs/features/hmis/ce-workflow-builders.md
module CeWorkflows::Az
  class WorkflowBuilder
    FORMS = {
      send_referral: 'mc_direct_referral_send_referral',
      provider_acknowledgement: 'mc_direct_referral_provider_acknowledgement',
      provider_decision: 'mc_direct_referral_provider_decision',
      post_referral_review: 'mc_direct_referral_post_referral_review',
    }.freeze

    # HUD CE Event ReferralResult codes
    SUCCESSFUL_REFERRAL = '1'
    CLIENT_REJECTED = '2'
    PROVIDER_REJECTED = '3'

    # Link ID of the Cancelled reason pick list, which the gateways read to decide whether HUD sees a
    # client rejection. Its sibling `declined_reason` needs no constant: the Declined branch routes on
    # the decision alone, since every Declined reason reports provider rejected.
    CANCELLED_REASON_LINK_ID = 'cancelled_reason'

    # A reason the provider can give for declining or cancelling a referral. `decision` is the Initial
    # Decision / Referral Outcome value that offers it, which also determines which form field it
    # lives on. `referral_result` is the HUD CE Event ReferralResult reported when it is chosen.
    # Keys and labels must stay in sync with the pick lists on the Provider Acknowledgement and
    # Provider Decision forms, which offer identical options. A spec asserts they match.
    DeclineReason = Struct.new(:key, :name, :decision, :referral_result, keyword_init: true)

    DECLINE_REASONS = [
      DeclineReason.new(key: 'program_declines_to_accept', name: 'Declined: Program declines to accept', decision: 'declined', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'referral_not_acted_on', name: 'Declined: Referral not acted on', decision: 'declined', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'already_obtained_permanent_housing', name: 'Cancelled: Already obtained permanent housing', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'multiple_outreach_attempts_unsuccessful', name: 'Cancelled: Multiple outreach attempts unsuccessful', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'cancelled_other', name: 'Cancelled: Other', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'ineligible_background_check', name: 'Client Ineligible: Background Check', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'ineligible_clinical_determination', name: 'Client Ineligible: Clinical Determination', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'ineligible_credit_check', name: 'Client Ineligible: Credit Check', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'ineligible_immigration_status', name: 'Client Ineligible: Immigration Status', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'ineligible_income_criteria', name: 'Client Ineligible: Income criteria', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'ineligible_third_party_verification_chronicity', name: 'Client Ineligible: Third Party Verification (Chronicity)', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'ineligible_unable_to_obtain_required_documentation', name: 'Client Ineligible: Unable to Obtain Required Documentation', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'ineligible_other', name: 'Client Ineligible: Other', decision: 'cancelled', referral_result: PROVIDER_REJECTED),
      DeclineReason.new(key: 'client_refused_didnt_want_unit_program', name: "Client Refused: Didn't want unit / program", decision: 'cancelled', referral_result: CLIENT_REJECTED),
      DeclineReason.new(key: 'client_refused_safety_concerns', name: 'Client Refused: Safety Concerns', decision: 'cancelled', referral_result: CLIENT_REJECTED),
      DeclineReason.new(key: 'client_refused_other', name: 'Client Refused: Other', decision: 'cancelled', referral_result: CLIENT_REJECTED),
    ].freeze

    def self.reasons_for(decision)
      DECLINE_REASONS.select { |reason| reason.decision == decision }
    end

    def initialize(data_source, unsafe_run_in_production: false)
      @data_source = data_source
      @unsafe_run_in_production = unsafe_run_in_production # flag to allow running in prod ONLY for initial setup

      missing = FORMS.values - Hmis::Form::Definition.
        in_data_source(@data_source.id).
        where(role: 'CE_REFERRAL_STEP', identifier: FORMS.values).
        pluck(:identifier)
      raise "Missing CE_REFERRAL_STEP forms: #{missing.join(', ')}" if missing.any?

      raise 'This class destroys data and should not be run in production' if Rails.env.production? && !@unsafe_run_in_production
    end

    # Must run before the template is built, because the template validator rejects forms that
    # collect a decline reason code with no matching ReferralDeclineReason row.
    def ensure_decline_reasons
      DECLINE_REASONS.each do |reason|
        record = Hmis::Ce::ReferralDeclineReason.find_or_initialize_by(key: reason.key, data_source: @data_source)
        record.name = reason.name
        record.save!
      end
    end

    def build_mc_direct_referral_workflow
      identifier = 'mc_direct_referral'
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(identifier, data_source: @data_source, delete_opportunities: false) unless @unsafe_run_in_production

      puts "Creating workflow definition template '#{identifier}'"
      template = CeWorkflows::Shared::CeBuilderUtils.create_template(identifier, 'Direct Referral', @data_source)

      ce_team_swimlane = template.swimlanes.create!(name: 'CE Team')
      provider_swimlane = template.swimlanes.create!(name: 'Provider')

      pending_status = find_or_create_status('pending', 'Pending')
      canceled_status = find_or_create_status('canceled', 'Canceled')
      # 'in_progress' is derived from the referral state machine, as are the terminal 'accepted' and
      # 'rejected' (labeled "Declined") statuses that accept_referral / reject_referral apply.
      in_progress_status = state_machine_status('in_progress')

      start_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_start_event(template)
      accept_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_accept_event(template)
      declined_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_decline_event(template)
      canceled_event = build_canceled_event(template, canceled_status)

      # Task 1: Referral Sent
      send_referral_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Referral Sent',
        form_definition_identifier: FORMS.fetch(:send_referral),
        template: template,
        swimlane: ce_team_swimlane,
        trigger_config: [status_trigger(pending_status)],
      )
      create_ce_event_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create CE Event',
        template: template,
        trigger_config: [{ event: 'complete_step', message: 'create_ce_event' }],
      )

      # Task 2: Provider Acknowledgement
      acknowledgement_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Provider Acknowledgement',
        form_definition_identifier: FORMS.fetch(:provider_acknowledgement),
        template: template,
        swimlane: provider_swimlane,
        trigger_config: [status_trigger(pending_status), decline_reason_trigger],
      )

      # Task 3: Provider Decision
      decision_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Provider Decision',
        form_definition_identifier: FORMS.fetch(:provider_decision),
        template: template,
        swimlane: provider_swimlane,
        trigger_config: [status_trigger(in_progress_status), decline_reason_trigger],
      )

      # Task 4: Post Referral Review
      post_review_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Post Referral Review',
        form_definition_identifier: FORMS.fetch(:post_referral_review),
        template: template,
        swimlane: provider_swimlane,
        trigger_config: [status_trigger(in_progress_status)],
      )

      # Terminal side effects. Each is shared by the Acknowledgement and Decision branches that need
      # it, since the pair of (CE Event result, terminal status) fully determines the outcome.
      enroll_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create Enrollment and close CE Event as "Successful referral: client accepted"',
        template: template,
        trigger_config: [
          { event: 'complete_step', message: 'create_enrollment' },
          { event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: SUCCESSFUL_REFERRAL } },
        ],
      )
      declined_ce_event_task = ce_event_result_task(template, 'Decline', PROVIDER_REJECTED)
      canceled_by_provider_ce_event_task = ce_event_result_task(template, 'Cancel', PROVIDER_REJECTED)
      canceled_by_client_ce_event_task = ce_event_result_task(template, 'Cancel', CLIENT_REJECTED)

      acknowledgement_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'initial_decision')
      decision_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'referral_outcome')

      start_event.connect_to!(send_referral_task)
      send_referral_task.connect_to!(create_ce_event_task)
      create_ce_event_task.connect_to!(acknowledgement_task)
      acknowledgement_task.connect_to!(acknowledgement_gateway)

      # Under Review leaves the CE Event open with no result and hands off to the provider's decision.
      # The remaining branches are terminal, and pick a CE Event result from the reason given.
      acknowledgement_gateway.connect_to!(decision_task, condition: "initial_decision = 'under_review'")
      acknowledgement_gateway.connect_to!(declined_ce_event_task, condition: "initial_decision = 'declined'")
      acknowledgement_gateway.connect_to!(canceled_by_client_ce_event_task, condition: cancelled_by_client_condition)
      acknowledgement_gateway.connect_to!(canceled_by_provider_ce_event_task) # Cancelled for any other reason

      decision_task.connect_to!(decision_gateway)
      decision_gateway.connect_to!(enroll_task, condition: "referral_outcome = 'accepted'")
      decision_gateway.connect_to!(declined_ce_event_task, condition: "referral_outcome = 'declined'")
      decision_gateway.connect_to!(canceled_by_client_ce_event_task, condition: cancelled_by_client_condition)
      decision_gateway.connect_to!(canceled_by_provider_ce_event_task) # Cancelled for any other reason

      declined_ce_event_task.connect_to!(declined_event)
      canceled_by_client_ce_event_task.connect_to!(canceled_event)
      canceled_by_provider_ce_event_task.connect_to!(canceled_event)

      # Acceptance already happened at Provider Decision, so Post Referral Review always ends the
      # referral as Accepted once submitted. 'successful' is tracked on the step for post-acceptance
      # problems but no longer gates the terminal status.
      enroll_task.connect_to!(post_review_task)
      post_review_task.connect_to!(accept_event)

      template.validate!
      template
    end

    private

    def status_trigger(status)
      { event: 'enable_step', message: 'set_custom_referral_status', params: { custom_status_key: status.key } }
    end

    def decline_reason_trigger
      { event: 'complete_step', message: 'set_referral_decline_reason' }
    end

    def find_or_create_status(key, name)
      status = Hmis::Ce::CustomReferralStatus.find_or_initialize_by(key: key, data_source: @data_source)
      status.name = name
      status.save!
      status
    end

    def state_machine_status(key)
      Hmis::Ce::CustomReferralStatus.find_by!(key: key, data_source: @data_source)
    rescue ActiveRecord::RecordNotFound
      raise "Missing CustomReferralStatus '#{key}'. Run CeBuilderUtils.create_state_machine_custom_statuses first."
    end

    def ce_event_result_task(template, verb, referral_result)
      Hmis::WorkflowDefinition::ScriptTask.create!(
        name: "#{verb} and close CE Event as \"#{HudHelper.util.referral_result(referral_result.to_i)}\"",
        template: template,
        trigger_config: [
          { event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: referral_result } },
        ],
      )
    end

    # reject_referral applies the state-machine derived 'rejected' status (labeled "Declined"), so the
    # Canceled override has to be triggered after it.
    def build_canceled_event(template, canceled_status)
      Hmis::WorkflowDefinition::EndEvent.create!(
        name: 'Referral Canceled',
        template: template,
        trigger_config: [
          { event: 'end_workflow', message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE },
          { event: 'end_workflow', message: 'set_custom_referral_status', params: { custom_status_key: canceled_status.key } },
        ],
      )
    end

    # Dentaku expression for the Cancelled branch that HUD considers a client rejection. Reads the
    # Cancelled field rather than the autofilled decline_reason, so a client-refused result is
    # unreachable from a Declined decision by construction. Both step forms use this same link ID;
    # the engine evaluates conditions against the most recently submitted value.
    def cancelled_by_client_condition
      self.class.reasons_for('cancelled').
        select { |reason| reason.referral_result == CLIENT_REJECTED }.
        map { |reason| "#{CANCELLED_REASON_LINK_ID} = '#{reason.key}'" }.
        join(' OR ')
    end
  end
end
