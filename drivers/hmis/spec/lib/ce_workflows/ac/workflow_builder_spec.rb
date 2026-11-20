###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CeWorkflows::Ac::WorkflowBuilder do
  # We intentionally build the templates (and the data source, seeded CE_REFERRAL_STEP forms, and custom
  # referral statuses they depend on) once in before(:all), rather than with the usual per-example
  # transactional fixtures. The class under test is a destroy-and-recreate builder: rebuilding the
  # templates per example would rerun its delete-and-recreate on every example.
  before(:all) do
    @data_source = create(:hmis_data_source)
    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(@data_source)
    HmisUtil::JsonForms.new(
      data_source_id: @data_source.id,
      env_key: 'allegheny',
      generate_cdeds: true,
    ).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
    builder = CeWorkflows::Ac::WorkflowBuilder.new(@data_source)
    @housing_template = builder.build_housing_workflow
    @obh_psh_template = builder.build_obh_psh_workflow
    @admin_assign_template = builder.build_admin_assign_workflow
  end

  after(:all) do
    ['housing_workflow_v1', 'obh_psh_workflow', 'admin_assign_workflow'].each do |identifier|
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(identifier, data_source: @data_source)
    end
    Hmis::Form::Instance.in_data_source(@data_source.id).delete_all
    Hmis::Form::Definition.in_data_source(@data_source.id).delete_all
    Hmis::Hud::CustomDataElementDefinition.where(data_source: @data_source).delete_all
    Hmis::Hud::CustomDataElement.where(data_source: @data_source).delete_all
    Hmis::Ce::CustomReferralStatus.where(data_source: @data_source).delete_all
    @data_source.destroy!
  end

  # Reload the before(:all) records each example so they're bound to the example's transaction and
  # don't carry cached associations across examples.
  let(:data_source) { GrdaWarehouse::DataSource.find(@data_source.id) }
  let(:housing_template) { Hmis::WorkflowDefinition::Template.find(@housing_template.id) }
  let(:obh_psh_template) { Hmis::WorkflowDefinition::Template.find(@obh_psh_template.id) }
  let(:admin_assign_template) { Hmis::WorkflowDefinition::Template.find(@admin_assign_template.id) }

  def user_tasks(template)
    template.nodes.
      where(type: Hmis::WorkflowDefinition::UserTask.sti_name).
      preload(:swimlane).
      order(:id)
  end

  # Custom referral status keys that a task sets when it is enabled
  def status_keys(task)
    status_triggers = task.triggers.select do |trigger|
      trigger.event == 'enable_step' && trigger.message == 'set_custom_referral_status'
    end
    status_triggers.map { |trigger| trigger.params.fetch('custom_status_key') }
  end

  describe '#build_obh_psh_workflow' do
    # The loop of Provider Outcome / Denial Review tasks is built twice (once after Provider Outcome,
    # once after Change Provider Outcome), so some names appear on more than one task. Compare distinct names.
    let(:tasks) { user_tasks(obh_psh_template) }
    let(:tasks_by_name) { tasks.group_by(&:name) }

    it 'creates a published, valid version 0 template' do
      expect(obh_psh_template).to have_attributes(
        identifier: 'obh_psh_workflow',
        name: 'OBH PSH Workflow',
        status: 'published',
        version: 0,
        data_source_id: data_source.id,
      )
      expect { obh_psh_template.validate! }.not_to raise_error
    end

    it 'names the user tasks as listed in the issue' do
      expect(tasks.map(&:name).uniq).to contain_exactly(
        'Initial Review',
        'Initial Referral Source Engagement',
        'Referral Source Engagement',
        'Offer Outcome',
        'Provider Outcome',
        'Change Provider Outcome',
        'Denial Review',
        'Provider Outcome (Second Attempt)',
        'Denial Review (Second Attempt)',
        'Provider Outcome (Third Attempt)',
        'Denial Review (Third Attempt)',
        'Confirm Success',
      )
    end

    it 'puts each task in the swimlane listed in the issue' do
      expect(obh_psh_template.swimlanes.pluck(:name)).to contain_exactly('DHS Staff', 'Provider Staff')

      expected_swimlanes = {
        'Initial Review' => 'DHS Staff',
        'Initial Referral Source Engagement' => 'DHS Staff',
        'Referral Source Engagement' => 'DHS Staff',
        'Offer Outcome' => 'DHS Staff',
        'Provider Outcome' => 'Provider Staff',
        'Change Provider Outcome' => 'Provider Staff',
        'Denial Review' => 'DHS Staff',
        'Provider Outcome (Second Attempt)' => 'Provider Staff',
        'Denial Review (Second Attempt)' => 'DHS Staff',
        'Provider Outcome (Third Attempt)' => 'Provider Staff',
        'Denial Review (Third Attempt)' => 'DHS Staff',
        'Confirm Success' => 'DHS Staff',
      }
      actual_swimlanes = tasks_by_name.transform_values do |named_tasks|
        named_tasks.map { |task| task.swimlane.name }.uniq
      end

      expect(actual_swimlanes).to eq(expected_swimlanes.transform_values { |swimlane| [swimlane] })
    end

    it 'sets the referral status for each task' do
      expected_status_keys = {
        'Initial Review' => ['matching_in_progress'],
        'Initial Referral Source Engagement' => [],
        'Referral Source Engagement' => [],
        'Offer Outcome' => [],
        'Provider Outcome' => ['assigned'],
        # Enrolled is set by Confirm Success, which is enabled alongside Change Provider Outcome
        'Change Provider Outcome' => [],
        'Denial Review' => ['denial_pending'],
        'Provider Outcome (Second Attempt)' => ['assigned'],
        'Denial Review (Second Attempt)' => ['denial_pending'],
        'Provider Outcome (Third Attempt)' => ['assigned'],
        'Denial Review (Third Attempt)' => ['denial_pending'],
        'Confirm Success' => ['enrolled'],
      }
      actual_status_keys = tasks_by_name.transform_values do |named_tasks|
        named_tasks.map { |task| status_keys(task) }.uniq
      end

      expect(actual_status_keys).to eq(expected_status_keys.transform_values { |keys| [keys] })
    end

    it 'reuses the housing workflow forms for the corresponding tasks' do
      housing_forms = user_tasks(housing_template).map(&:form_definition_identifier)
      obh_psh_forms = tasks.map(&:form_definition_identifier)

      expect(obh_psh_forms).to eq(housing_forms)

      # Spot-check that renamed tasks use the form keyed to the same step
      described_class::OBH_PSH_WORKFLOW_NAMES.except(:ce_staff_swimlane, :project_staff_swimlane).each do |key, name|
        form_identifiers = tasks_by_name.fetch(name).map(&:form_definition_identifier).uniq
        expect(form_identifiers).to eq([described_class::CE_STEP_FORMS.fetch(key)])
      end
    end
  end

  describe '#build_housing_workflow' do
    let(:tasks) { user_tasks(housing_template) }

    it 'keeps the existing task and swimlane names' do
      expected_task_names = described_class::HOUSING_WORKFLOW_NAMES.
        except(:ce_staff_swimlane, :project_staff_swimlane).
        values

      expect(tasks.map(&:name).uniq).to contain_exactly(*expected_task_names)
      expect(expected_task_names).to include(
        'Initial Client Engagement',
        'Client Engagement',
        'Client Offer Outcome',
        'Change Provider Outcome (Optional)',
        'Denial Review (Second)',
        'Denial Review (Third)',
      )
      expect(housing_template.swimlanes.pluck(:name)).to contain_exactly('CE Staff', 'Project Staff')
    end

    it 'has the same graph shape as the OBH PSH workflow' do
      expect(housing_template.nodes.count).to eq(obh_psh_template.nodes.count)
      expect(housing_template.flows.count).to eq(obh_psh_template.flows.count)
      expect(housing_template.nodes.order(:id).pluck(:type)).to eq(obh_psh_template.nodes.order(:id).pluck(:type))
    end
  end

  describe '#build_admin_assign_workflow' do
    let(:tasks) { user_tasks(admin_assign_template) }

    it 'keeps the existing task and swimlane names' do
      # Admin Assign shares the provider outcome / denial review sub-workflow, which takes its names
      # from HOUSING_WORKFLOW_NAMES. Its own first step is 'Admin Assign'.
      expected_swimlanes = {
        'Admin Assign' => 'CE Staff',
        'Provider Outcome' => 'Project Staff',
        'Change Provider Outcome (Optional)' => 'Project Staff',
        'Denial Review' => 'CE Staff',
        'Provider Outcome (Second Attempt)' => 'Project Staff',
        'Denial Review (Second)' => 'CE Staff',
        'Provider Outcome (Third Attempt)' => 'Project Staff',
        'Denial Review (Third)' => 'CE Staff',
        'Confirm Success' => 'CE Staff',
      }
      actual_swimlanes = tasks.group_by(&:name).transform_values do |named_tasks|
        named_tasks.map { |task| task.swimlane.name }.uniq
      end

      expect(admin_assign_template.swimlanes.pluck(:name)).to contain_exactly('CE Staff', 'Project Staff')
      expect(actual_swimlanes).to eq(expected_swimlanes.transform_values { |swimlane| [swimlane] })
      expect { admin_assign_template.validate! }.not_to raise_error
    end
  end

  describe 'production guard' do
    let(:unsafe_builder) { described_class.new(data_source, unsafe_run_in_production: true) }

    it 'does not delete existing template data when run with unsafe_run_in_production' do
      # Remove the template built in before(:all) (rolled back after this example), so the
      # builder can create it again without deleting anything itself.
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data('obh_psh_workflow', data_source: data_source)
      housing_referral = create(
        :hmis_ce_referral,
        data_source: data_source,
        workflow_template: housing_template,
      )

      expect(CeWorkflows::Shared::CeBuilderUtils).not_to receive(:delete_template_and_associated_data)

      template = unsafe_builder.build_obh_psh_workflow

      expect(template).to be_persisted
      expect(template.identifier).to eq('obh_psh_workflow')
      expect(Hmis::WorkflowDefinition::Template.exists?(housing_template.id)).to be(true)
      expect(Hmis::Ce::Referral.exists?(housing_referral.id)).to be(true)
    end

    it 'keeps referrals on an existing OBH PSH template when rerun with unsafe_run_in_production' do
      obh_psh_referral = create(
        :hmis_ce_referral,
        data_source: data_source,
        workflow_template: obh_psh_template,
      )

      # Version 0 already exists, so a rerun fails on version uniqueness instead of replacing the template
      expect { unsafe_builder.build_obh_psh_workflow }.to raise_error(ActiveRecord::RecordInvalid)

      expect(Hmis::WorkflowDefinition::Template.exists?(obh_psh_template.id)).to be(true)
      expect(Hmis::Ce::Referral.exists?(obh_psh_referral.id)).to be(true)
    end
  end
end
