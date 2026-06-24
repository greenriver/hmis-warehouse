###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Form::Instance, type: :model do
  let(:ds1) { create(:hmis_primary_data_source) }
  let(:p1) { create(:hmis_hud_project, data_source: ds1) }
  let(:identifier) { 'instance_spec_form' }

  describe '#definition' do
    it 'resolves the definition for this instance data_source_id and definition_identifier' do
      definition = create(:hmis_form_definition, data_source: ds1, identifier: identifier, status: :published, role: :UPDATE)
      instance = create(:hmis_form_instance, entity: p1, data_source: ds1, definition_identifier: identifier)

      expect(instance.reload.definition).to eq(definition)
    end

    it 'prefers published over draft when multiple versions share the identifier in this data source' do
      create(:hmis_form_definition, data_source: ds1, identifier: identifier, status: :draft, version: 2, role: :UPDATE)
      published = create(:hmis_form_definition, data_source: ds1, identifier: identifier, status: :published, version: 1, role: :UPDATE)
      instance = create(:hmis_form_instance, entity: p1, data_source: ds1, definition_identifier: identifier)

      expect(instance.reload.definition).to eq(published)
    end

    it 'returns retired form only if no published form exists' do
      retired = create(:hmis_form_definition, data_source: ds1, identifier: identifier, status: :retired, version: 1, role: :UPDATE)
      instance = create(:hmis_form_instance, entity: p1, data_source: ds1, definition_identifier: identifier)

      expect(instance.reload.definition).to eq(retired)
    end

    it 'does not resolve a definition that only matches on identifier in a different data source' do
      create(:hmis_form_definition, identifier: identifier, status: :published, role: :UPDATE)
      ds1_definition = create(:hmis_form_definition, data_source: ds1, identifier: identifier, status: :draft, role: :UPDATE)
      instance = create(:hmis_form_instance, entity: p1, data_source: ds1, definition_identifier: identifier)

      expect(instance.reload.definition).to eq(ds1_definition)
    end
  end

  describe '#definitions' do
    it 'returns all definition rows for this data_source_id and definition_identifier' do
      published = create(:hmis_form_definition, data_source: ds1, identifier: identifier, status: :published, version: 1, role: :UPDATE)
      draft = create(:hmis_form_definition, data_source: ds1, identifier: identifier, status: :draft, version: 2, role: :UPDATE)
      instance = create(:hmis_form_instance, entity: p1, data_source: ds1, definition_identifier: identifier)

      expect(instance.reload.definitions).to match_array([published, draft])
    end

    it 'excludes definitions with the same identifier in another data source' do
      create(:hmis_form_definition, identifier: identifier, status: :published, role: :UPDATE)
      ds1_definition = create(:hmis_form_definition, data_source: ds1, identifier: identifier, status: :published, role: :UPDATE)
      instance = create(:hmis_form_instance, entity: p1, data_source: ds1, definition_identifier: identifier)

      expect(instance.reload.definitions).to eq([ds1_definition])
    end
  end

  describe '#with_role' do
    include_context 'hmis base setup'
    include_context 'hmis json forms seed'

    let(:role) { 'CUSTOM_ASSESSMENT' }

    let!(:assessment_definition) { create :hmis_form_definition, identifier: 'my_custom_assessment', role: role, data_source: ds1 }
    let!(:old_assessment_definition) { create :hmis_form_definition, identifier: 'my_custom_assessment', status: 'retired', version: 0, role: role, data_source: ds1 }
    let!(:instance1) { create(:hmis_form_instance, role: role, project_type: 2, active: true, definition: assessment_definition, data_source: ds1) }
    let!(:instance2) { create(:hmis_form_instance, role: role, project_type: 3, active: true, definition: assessment_definition, data_source: ds1) }

    let(:intake_form) { Hmis::Form::Definition.managed_in_version_control.find_by!(role: 'INTAKE') }
    let!(:instance3) { create(:hmis_form_instance, role: 'INTAKE', project_type: 3, active: true, definition: intake_form, data_source: ds1) }

    it 'returns rules with the expected scope without duplicates (regression #8617)' do
      scope = Hmis::Form::Instance.with_role(role)
      expect(scope.count).to eq(2)
      expect(scope).to contain_exactly(instance1, instance2)
    end
  end
end
