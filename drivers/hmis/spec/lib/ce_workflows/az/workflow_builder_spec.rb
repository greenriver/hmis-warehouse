###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CeWorkflows::Az::WorkflowBuilder do
  # We intentionally build the template (and the data source, seeded CE_REFERRAL_STEP forms, decline
  # reasons, and custom referral statuses it depends on) once in before(:all), rather than with the
  # usual per-example transactional fixtures. The class under test is a destroy-and-recreate builder:
  # rebuilding the template per example would rerun its delete-and-recreate on every example.
  before(:all) do
    @data_source = create(:hmis_data_source)
    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(@data_source)
    HmisUtil::JsonForms.new(
      data_source_id: @data_source.id,
      env_key: 'az',
      generate_cdeds: true,
    ).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
    builder = CeWorkflows::Az::WorkflowBuilder.new(@data_source)
    builder.ensure_decline_reasons
    @template = builder.build_mc_direct_referral_workflow
  end

  after(:all) do
    CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data('mc_direct_referral', data_source: @data_source)
    Hmis::Form::Instance.in_data_source(@data_source.id).delete_all
    Hmis::Form::Definition.in_data_source(@data_source.id).delete_all
    Hmis::Hud::CustomDataElementDefinition.where(data_source: @data_source).delete_all
    Hmis::Hud::CustomDataElement.where(data_source: @data_source).delete_all
    Hmis::Ce::ReferralDeclineReason.where(data_source: @data_source).delete_all
    Hmis::Ce::CustomReferralStatus.where(data_source: @data_source).delete_all
    @data_source.destroy!
  end

  # Reload the before(:all) records each example so they're bound to the example's transaction and
  # don't carry cached associations across examples.
  let(:data_source) { GrdaWarehouse::DataSource.find(@data_source.id) }
  let(:template) { Hmis::WorkflowDefinition::Template.find(@template.id) }

  let!(:user) { create(:hmis_user, data_source: data_source) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
  let!(:project) { create(:hmis_hud_project, data_source: data_source) }

  let(:send_referral_values) do
    {
      'referral_date' => Date.current.iso8601,
      'referral_type' => 'psh',
      'case_manager' => 'Casey Manager',
    }
  end
  let(:under_review) { { 'referral_review_start' => Date.current.iso8601, 'initial_decision' => 'under_review' } }

  # The provider answers one of two reason pick lists, and the form autofills the hidden
  # `decline_reason` from whichever one applies. These helpers submit what the frontend would send.
  def reason_values(decision, reason)
    return {} if reason.nil?

    link_id = decision == 'declined' ? 'declined_reason' : 'canceled_reason'
    { link_id => reason, 'decline_reason' => reason }
  end

  def acknowledgement(decision, reason = nil)
    { 'referral_review_start' => Date.current.iso8601, 'initial_decision' => decision }.merge(reason_values(decision, reason))
  end

  def decision(outcome, reason = nil)
    { 'decision_date' => Date.current.iso8601, 'referral_outcome' => outcome }.merge(reason_values(outcome, reason))
  end

  def post_review(successful)
    { 'psh_documents' => true, 'psh_inspection' => true, 'successful' => successful }
  end

  shared_context 'az direct referral walkthrough' do
    let(:pending_status) { Hmis::Ce::CustomReferralStatus.find_by!(key: 'pending', data_source: data_source) }
    let(:in_progress_status) { Hmis::Ce::CustomReferralStatus.find_by!(key: 'in_progress', data_source: data_source) }
    let(:canceled_status) { Hmis::Ce::CustomReferralStatus.find_by!(key: 'canceled', data_source: data_source) }
    let(:declined_status) { Hmis::Ce::CustomReferralStatus.find_by!(key: 'rejected', data_source: data_source) }

    let!(:source_project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }
    let!(:source_enrollment) do
      create(:hmis_hud_enrollment, data_source: data_source, project: source_project, client: client, entry_date: 30.days.ago)
    end
    # PSH (project type 3) referrals report CE event type 18, "Referral to PSH project resource opening".
    let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: template, ce_event_type: 18) }
    let!(:unit) { create(:hmis_unit, project: project, unit_group: unit_group) }
    let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit) }
    let!(:referral) do
      create(
        :hmis_ce_referral,
        client: client,
        opportunity: opportunity,
        source_enrollment: source_enrollment,
        workflow_instance: template.instances.create!,
        referred_by: user,
        status: 'initialized',
      )
    end
    let(:engine) { referral.workflow_engine }
    let!(:access_control) do
      create_access_control(
        user,
        data_source,
        with_permission: [
          :can_view_clients,
          :can_view_project,
          :can_view_enrollment_details,
          :can_edit_enrollments,
          :can_enroll_clients,
        ],
      )
    end
    let!(:project_coc) { create(:hmis_hud_project_coc, data_source: data_source, project: project, coc_code: 'CO-500') }

    before do
      template.swimlanes.each { |swimlane| referral.participants.create!(swimlane: swimlane, user: user) }
      engine.start_workflow!(user: user)
    end

    # Completes Referral Sent, which creates the CE Event and opens Provider Acknowledgement.
    def send_referral!
      complete_user_step!(engine, 'Referral Sent', submitted_values: send_referral_values, user: user)
    end

    # Completes Referral Sent and an Under Review acknowledgement, leaving Provider Decision open.
    def advance_to_provider_decision!
      send_referral!
      complete_user_step!(engine, 'Provider Acknowledgement', submitted_values: under_review, user: user)
    end

    # Drives all the way to an accepted Provider Decision, leaving Post Referral Review open.
    def advance_to_post_referral_review!
      advance_to_provider_decision!
      complete_user_step!(engine, 'Provider Decision', submitted_values: decision('accepted'), user: user)
    end
  end

  # The reason pick lists are duplicated between the builder (which seeds ReferralDeclineReason and
  # builds the gateway conditions) and the step form JSON. These guard against the two drifting.
  describe 'reason pick lists' do
    let(:declined_keys) { described_class.reasons_for('declined').map(&:key) }
    let(:canceled_keys) { described_class.reasons_for('canceled').map(&:key) }

    def option_codes(identifier, link_id)
      definition = Hmis::Form::Definition.in_data_source(data_source.id).find_by!(identifier: identifier, role: 'CE_REFERRAL_STEP')
      definition.link_id_item_hash.fetch(link_id).pick_list_options.map(&:code)
    end

    ['mc_direct_referral_provider_acknowledgement', 'mc_direct_referral_provider_decision'].each do |identifier|
      describe identifier do
        it 'offers only the Declined reasons under Declined' do
          expect(option_codes(identifier, 'declined_reason')).to eq(declined_keys)
        end

        it 'offers only the Canceled reasons under Canceled' do
          expect(option_codes(identifier, 'canceled_reason')).to eq(canceled_keys)
        end

        # The hidden field feeds set_referral_decline_reason, so it has to accept either list.
        it 'accepts the union of both lists on the hidden decline_reason field' do
          expect(option_codes(identifier, 'decline_reason')).to match_array(described_class::DECLINE_REASONS.map(&:key))
        end

        # createValuesForSubmit drops items with no mapping, so without this the autofilled
        # value never reaches submitted_values and ReferralMessageHandler records nothing.
        it 'maps the hidden decline_reason field so the frontend submits it' do
          definition = Hmis::Form::Definition.in_data_source(data_source.id).find_by!(identifier: identifier, role: 'CE_REFERRAL_STEP')
          mapping = definition.link_id_item_hash.fetch('decline_reason').mapping
          expect(mapping.custom_field_key).to be_present
        end
      end
    end

    it 'seeds a ReferralDeclineReason for every option' do
      expect(Hmis::Ce::ReferralDeclineReason.where(data_source: data_source).pluck(:key)).
        to match_array(described_class::DECLINE_REASONS.map(&:key))
    end
  end

  describe 'projected steps' do
    it 'projects the happy-path user tasks for a new referral' do
      projected = template.graph(preloads: :inflows).
        walk(stop_when: lambda(&:conditional_inflows?)).
        filter(&:user_task?).
        reject(&:conditional_inflows?).
        map(&:name)

      expect(projected).to eq(['Referral Sent', 'Provider Acknowledgement'])
    end
  end

  describe 'Referral Sent' do
    include_context 'az direct referral walkthrough'

    it 'opens as Pending and creates an open CE Event before the provider acknowledges' do
      expect(referral.reload.custom_status).to eq(pending_status)
      expect(referral.ce_event).to be_nil

      send_referral!

      expect_active_steps(engine, 'Provider Acknowledgement')
      expect(referral.reload.ce_event).to be_present
      expect(referral.ce_event.referral_result).to be_nil
      expect(referral.custom_status).to eq(pending_status)
    end
  end

  describe 'Provider Acknowledgement' do
    include_context 'az direct referral walkthrough'

    before { send_referral! }

    it 'continues to Provider Decision on Under Review, leaving the CE Event open' do
      complete_user_step!(engine, 'Provider Acknowledgement', submitted_values: under_review, user: user)

      expect_active_steps(engine, 'Provider Decision')
      referral.reload
      expect(referral.custom_status).to eq(in_progress_status)
      expect(referral.ce_event.referral_result).to be_nil
      expect(referral.decline_reason).to be_nil
    end

    it 'declines with provider rejected (3) and records the decline reason' do
      complete_user_step!(
        engine,
        'Provider Acknowledgement',
        submitted_values: acknowledgement('declined', 'program_declines_to_accept'),
        user: user,
      )

      expect_rejected(referral, result: 3)
      expect(referral.custom_status).to eq(declined_status)
      expect(referral.decline_reason.key).to eq('program_declines_to_accept')
      expect(engine.active_steps).to be_empty
    end

    it 'cancels with client rejected (2) when the reason is a Client Refused reason' do
      complete_user_step!(
        engine,
        'Provider Acknowledgement',
        submitted_values: acknowledgement('canceled', 'client_refused_safety_concerns'),
        user: user,
      )

      expect_rejected(referral, result: 2)
      expect(referral.custom_status).to eq(canceled_status)
      expect(referral.decline_reason.key).to eq('client_refused_safety_concerns')
    end

    it 'cancels with provider rejected (3) for any other cancellation reason' do
      complete_user_step!(
        engine,
        'Provider Acknowledgement',
        submitted_values: acknowledgement('canceled', 'ineligible_income_criteria'),
        user: user,
      )

      expect_rejected(referral, result: 3)
      expect(referral.custom_status).to eq(canceled_status)
    end
  end

  describe 'Provider Decision' do
    include_context 'az direct referral walkthrough'

    before { advance_to_provider_decision! }

    it 'enrolls the client and closes the CE Event as successful without accepting the referral yet' do
      complete_user_step!(engine, 'Provider Decision', submitted_values: decision('accepted'), user: user)

      expect_active_steps(engine, 'Post Referral Review')
      referral.reload
      expect(referral.status).to eq('in_progress')
      expect(referral.target_enrollment).to be_present
      expect(referral.ce_event.referral_result).to eq(1)
      expect(referral.custom_status).to eq(in_progress_status)
    end

    it 'declines with provider rejected (3) and records the decline reason' do
      complete_user_step!(engine, 'Provider Decision', submitted_values: decision('declined', 'referral_not_acted_on'), user: user)

      expect_rejected(referral, result: 3)
      expect(referral.custom_status).to eq(declined_status)
      expect(referral.decline_reason.key).to eq('referral_not_acted_on')
    end

    it 'cancels with client rejected (2) when the reason is a Client Refused reason' do
      complete_user_step!(engine, 'Provider Decision', submitted_values: decision('canceled', 'client_refused_other'), user: user)

      expect_rejected(referral, result: 2)
      expect(referral.custom_status).to eq(canceled_status)
    end

    it 'cancels with provider rejected (3) for any other cancellation reason' do
      complete_user_step!(engine, 'Provider Decision', submitted_values: decision('canceled', 'canceled_other'), user: user)

      expect_rejected(referral, result: 3)
      expect(referral.custom_status).to eq(canceled_status)
    end
  end

  describe 'Post Referral Review' do
    include_context 'az direct referral walkthrough'

    before { advance_to_post_referral_review! }

    it 'accepts the referral when the review is successful' do
      complete_user_step!(engine, 'Post Referral Review', submitted_values: post_review(true), user: user)

      expect_accepted(referral)
      expect(engine.active_steps).to be_empty
    end

    # Acceptance already happened at Provider Decision, so an unsuccessful review still ends the
    # referral as Accepted -- 'successful' only tracks post-acceptance problems, it doesn't decline.
    it 'accepts the referral even when the review is unsuccessful' do
      complete_user_step!(engine, 'Post Referral Review', submitted_values: post_review(false), user: user)

      expect_accepted(referral)
      expect(engine.active_steps).to be_empty
    end
  end
end
