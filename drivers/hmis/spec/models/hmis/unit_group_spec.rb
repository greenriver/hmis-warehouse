# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::UnitGroup, type: :model do
  include_context 'hmis base setup'
  let!(:project) { create(:hmis_hud_project) }
  let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: nil, direct_referral_workflow_template: nil) }

  describe 'validations' do
    it 'prevents the project from being changed' do
      new_project = create(:hmis_hud_project)
      unit_group.project = new_project
      expect(unit_group).not_to be_valid
      expect(unit_group.errors[:project]).to include('cannot be changed')
    end

    it 'validates data source' do
      workflow_template = create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: create(:grda_warehouse_data_source))

      unit_group.workflow_template = workflow_template
      unit_group.direct_referral_workflow_template = workflow_template
      expect(unit_group).not_to be_valid
      expect(unit_group.errors[:workflow_template_identifier]).to include('must belong to the same data source')
      expect(unit_group.errors[:direct_referral_workflow_template_identifier]).to include('must belong to the same data source')
    end

    it 'validates template type' do
      workflow_template = create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: project.data_source, template_type: 'not_ce')

      unit_group.workflow_template = workflow_template
      expect(unit_group).not_to be_valid
      expect(unit_group.errors[:workflow_template_identifier]).to include('must have a template type of ce_referral')

      unit_group.direct_referral_workflow_template = workflow_template
      expect(unit_group).not_to be_valid
      expect(unit_group.errors[:direct_referral_workflow_template_identifier]).to include('must have a template type of ce_referral')
    end

    it 'validates status' do
      workflow_template = create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: project.data_source, status: 'draft')

      unit_group.workflow_template = workflow_template
      expect(unit_group).not_to be_valid
      expect(unit_group.errors[:workflow_template_identifier]).to include('must be published')

      unit_group.direct_referral_workflow_template = workflow_template
      expect(unit_group).not_to be_valid
      expect(unit_group.errors[:direct_referral_workflow_template_identifier]).to include('must be published')
    end

    it 'validates direct referral workflow template structure' do
      direct_referral_workflow_template = create(:hmis_workflow_definition_template, data_source: project.data_source, status: 'published', template_type: 'ce_referral')
      unit_group.direct_referral_workflow_template = direct_referral_workflow_template
      expect(unit_group).not_to be_valid
      expect(unit_group.errors[:direct_referral_workflow_template_identifier]).to include('structure is not valid for direct referrals')
    end

    it 'accepts valid workflow template' do
      workflow_template = create(:hmis_workflow_definition_template, data_source: project.data_source, status: 'published', template_type: 'ce_referral')
      unit_group.workflow_template = workflow_template
      expect(unit_group).to be_valid
    end

    it 'accepts valid direct referral workflow template' do
      direct_referral_workflow_template = create(:hmis_workflow_definition_template, data_source: project.data_source, status: 'published', template_type: 'ce_referral')
      unit_group.direct_referral_workflow_template = direct_referral_workflow_template

      start_event = create(:hmis_workflow_definition_start_event, template: direct_referral_workflow_template)
      user_task = create(:hmis_workflow_definition_user_task, template: direct_referral_workflow_template)
      start_event.connect_to!(user_task)
      expect(unit_group).to be_valid
    end

    context 'with existing workflow templates' do
      let!(:workflow_template) { create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: project.data_source) }
      let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: workflow_template, direct_referral_workflow_template: workflow_template) }

      it 'prevents the workflow template from being changed' do
        new_workflow_template = create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: project.data_source)
        unit_group.workflow_template = new_workflow_template
        expect(unit_group).not_to be_valid
        expect(unit_group.errors[:workflow_template_identifier]).to include('cannot be changed once set')
      end

      it 'prevents the direct referral workflow template from being changed' do
        direct_referral_workflow_template = create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: project.data_source)
        unit_group.reload.direct_referral_workflow_template = direct_referral_workflow_template
        expect(unit_group).not_to be_valid
        expect(unit_group.errors[:direct_referral_workflow_template_identifier]).to include('cannot be changed once set')
      end
    end
  end

  describe 'callbacks' do
    before do
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    end

    it 'calls CandidatePoolBuilder after creation with its own id' do
      new_unit_group = create(:hmis_unit_group, project: project)
      expect(Hmis::Ce::Match::CandidatePoolBuilder).to have_received(:call).with(unit_group_ids: [new_unit_group.id])
    end
  end

  describe 'paranoia' do
    let(:build_record) { -> { create(:hmis_unit_group, project: create(:hmis_hud_project)) } }

    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    let(:build_record) { -> { create(:hmis_unit_group, project: create(:hmis_hud_project)) } }
    let(:update_attributes_for_versioning) { ->(record) { record.update!(name: "Updated #{record.name}") } }

    it_behaves_like 'versioned model'
  end
end
