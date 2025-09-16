# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'forms rake tasks', type: :task do
  let(:task_name) { 'forms:backfill_custom_data_element_form_definitions' }

  before do
    Rake::Task.clear
    Rake.application = Rake::Application.new
    # Load only the forms tasks under test
    load Rails.root.join('drivers/hmis/lib/tasks/forms.rake')
    # Stub environment dependency declared by the task
    Rake::Task.define_task(:environment)

    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
  end

  def run_task(identifier)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke(identifier)
  end

  describe 'forms:backfill_custom_data_element_form_definitions' do
    it 'backfills form_definition_identifier for matching CDEDs derived from the form items' do
      data_source = create(:hmis_data_source)

      definition_json = {
        'item' => [
          { 'type' => 'STRING', 'link_id' => 'one', 'mapping' => { 'custom_field_key' => 'key1' } },
          { 'type' => 'STRING', 'link_id' => 'two', 'mapping' => { 'custom_field_key' => 'key2' } },
        ],
      }

      form = create(
        :hmis_form_definition,
        identifier: 'my_form',
        role: 'CUSTOM_ASSESSMENT',
        definition: definition_json,
      )

      cded1 = create(
        :hmis_custom_data_element_definition,
        owner_type: 'Hmis::Hud::CustomAssessment',
        key: 'key1',
        data_source: data_source,
        form_definition_identifier: nil,
      )
      cded2 = create(
        :hmis_custom_data_element_definition,
        owner_type: 'Hmis::Hud::CustomAssessment',
        key: 'key2',
        data_source: data_source,
        form_definition_identifier: nil,
      )

      expect { run_task(form.identifier) }.
        to change { cded1.reload.form_definition_identifier }.
        from(nil).to('my_form').
        and change { cded2.reload.form_definition_identifier }.
        from(nil).to('my_form')
    end

    it 'raises if a matching CDED is already tied to a different form' do
      data_source = create(:hmis_data_source)

      definition_json = {
        'item' => [
          { 'type' => 'STRING', 'link_id' => 'one', 'mapping' => { 'custom_field_key' => 'conflict_key' } },
        ],
      }

      form = create(
        :hmis_form_definition,
        identifier: 'target_form',
        role: 'CUSTOM_ASSESSMENT',
        definition: definition_json,
      )

      create(
        :hmis_custom_data_element_definition,
        owner_type: 'Hmis::Hud::CustomAssessment',
        key: 'conflict_key',
        data_source: data_source,
        form_definition_identifier: 'other_form',
      )

      expect { run_task(form.identifier) }.
        to raise_error(/unexpected form/i)
    end
  end
end
