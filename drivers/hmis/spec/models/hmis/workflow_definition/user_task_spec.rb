###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::WorkflowDefinition::UserTask, type: :model do
  let!(:ds1) { create(:hmis_data_source) }
  let!(:template) { create(:hmis_workflow_definition_template, data_source: ds1) }
  let!(:form_identifier) { 'workflow_step_form' }

  describe 'form_definitions and form_definition associations' do
    let!(:published_form) do
      create(
        :hmis_form_definition,
        data_source: ds1,
        identifier: form_identifier,
        version: 1,
        status: :published,
      )
    end

    let!(:draft_form) do
      create(
        :hmis_form_definition,
        data_source: ds1,
        identifier: form_identifier,
        version: 2,
        status: :draft,
      )
    end

    let(:user_task) do
      create(
        :hmis_workflow_definition_user_task,
        template: template,
        form_definition_identifier: form_identifier,
      )
    end

    it 'associates to all form definition versions for the identifier in the template data source' do
      expect(user_task.form_definitions).to contain_exactly(published_form, draft_form)
    end

    it 'resolves form_definition to the published version only' do
      expect(user_task.form_definition).to eq(published_form)
    end

    it 'does not associate to definitions with the same identifier in another data source' do
      ds2 = create(:hmis_data_source)
      other_ds_form = create(
        :hmis_form_definition,
        data_source: ds2,
        identifier: form_identifier,
        version: 1,
        status: :published,
      )

      expect(user_task.form_definitions).not_to include(other_ds_form)
      expect(user_task.form_definition).not_to eq(other_ds_form)
    end
  end
end
