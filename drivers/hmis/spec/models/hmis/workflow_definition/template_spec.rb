# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::WorkflowDefinition::Template, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    -> { create(:hmis_workflow_definition_template, data_source: ds1) }
  end

  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(name: "Updated #{record.name}") }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end

  describe 'latest_versions with acts_as_paranoid' do
    it 'resolves latest non-deleted template in associations (UnitGroup -> workflow_template)' do
      identifier = 'ce-template-for-assoc-test'
      project = create(:hmis_hud_project, data_source: ds1)

      v1 = create(:hmis_workflow_definition_template,
                  data_source: ds1,
                  identifier: identifier,
                  version: 1,
                  status: Hmis::Form::Definition::RETIRED)

      v2 = create(:hmis_workflow_definition_template,
                  data_source: ds1,
                  identifier: identifier,
                  version: 2,
                  status: Hmis::Form::Definition::PUBLISHED)
      # Soft-delete the highest version
      v2.destroy!

      # re-publish the old version
      v1.update!(status: Hmis::Form::Definition::PUBLISHED)

      # Associate a UnitGroup by identifier; it should resolve to the latest non-deleted (v1)
      unit_group = create(:hmis_unit_group,
                          project: project,
                          workflow_template_identifier: identifier)

      # Expected: association finds v1, not nil, even though v2 is soft-deleted
      expect(unit_group.workflow_template).to eq(v1)
    end
  end

  describe '.used_in_projects' do
    let!(:project1) { create(:hmis_hud_project, data_source: ds1) }
    let!(:project2) { create(:hmis_hud_project, data_source: ds1) }

    let!(:template1) { create(:hmis_workflow_definition_template, data_source: ds1, identifier: 'template-1') }
    let!(:template2) { create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: ds1, identifier: 'template-2') }
    let!(:unused_template) { create(:hmis_workflow_definition_template, data_source: ds1, identifier: 'unused-template') }

    let!(:unit_group1) { create(:hmis_unit_group, project: project1, workflow_template_identifier: template1.identifier) }
    let!(:unit_group2) { create(:hmis_unit_group, project: project2, workflow_template_identifier: nil, direct_referral_workflow_template_identifier: template2.identifier) }

    it 'returns templates used by workflow_template_identifier in given projects' do
      result = described_class.used_in_projects([project1.id])
      expect(result).to contain_exactly(template1)
    end

    it 'returns templates used by direct_referral_workflow_template_identifier in given projects' do
      result = described_class.used_in_projects([project2.id])
      expect(result).to contain_exactly(template2)
    end

    it 'does not return duplicate templates when used in multiple unit groups' do
      # Create another unit group in project1 also using template1
      create(:hmis_unit_group, project: project1, workflow_template_identifier: template1.identifier)

      result = described_class.used_in_projects([project1.id])
      expect(result).to contain_exactly(template1)
    end
  end
end
