# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/submit_form_spec_helpers'
require_relative '../../support/shared_examples/submit_form'

RSpec.describe 'SubmitForm for CaseNote', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }
  let!(:custom_case_note) { create(:hmis_hud_custom_case_note, data_source: ds1, client: c1, enrollment: e1, user: u1) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :CASE_NOTE) }

  let(:hud_values) do
    {
      'content' => 'test',
    }
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      enrollment_id: e1.id,
      confirmed: true,
    }
  end

  it_behaves_like 'submit form updates HUD User on record'

  it 'saves a new case note' do
    record, = submit_form(input)
    case_note = Hmis::Hud::CustomCaseNote.find(record['id'])
    expect(case_note.content).to eq('test')
  end

  it 'persists submitted form values to an existing case note' do
    expect do
      submit_form(input.merge(record_id: custom_case_note.id))
      custom_case_note.reload
    end.to change(custom_case_note, :content).to('test').
      and not_change(Hmis::Hud::CustomCaseNote, :count)
  end

  context 'when user lacks can_edit_enrollments permission' do
    before { remove_permissions(access_control, :can_edit_enrollments) }

    it 'returns access denied' do
      expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
    end
  end

  context 'when form creates case note with related current living situation' do
    let(:information_date) { 1.week.ago.to_date }

    let(:definition_json) do
      {
        "item": [
          {
            # CaseNote.content field
            "type": 'TEXT',
            "required": false,
            "link_id": 'note',
            "mapping": {
              "field_name": 'content',
            },
          },
          {
            # CurrentLivingSituation.informationDate field
            "type": 'DATE',
            "required": false,
            "link_id": 'date',
            "mapping": {
              "record_type": 'CURRENT_LIVING_SITUATION',
              "field_name": 'informationDate',
            },
          },
          {
            # CurrentLivingSituation.currentLivingSituation field
            "type": 'CHOICE',
            "required": false,
            "link_id": 'cls',
            "mapping": {
              "record_type": 'CURRENT_LIVING_SITUATION',
              "field_name": 'currentLivingSituation',
            },
          },
        ],
      }
    end
    let!(:definition) { create :hmis_form_definition, role: :CASE_NOTE, definition: definition_json }
    let(:hud_values) do
      {
        'content' => 'test',
        'CurrentLivingSituation.informationDate' => information_date.strftime('%Y-%m-%d'),
        'CurrentLivingSituation.currentLivingSituation' => 'SAFE_HAVEN', # 118
      }
    end

    it 'creates new CustomCaseNote with new CurrentLivingSituation attached' do
      record, = submit_form(input)

      case_note = Hmis::Hud::CustomCaseNote.find(record['id'])
      cls = case_note.form_processor.current_living_situation
      expect(cls).to be_present
      expect(cls.information_date).to eq(information_date)
      expect(cls.current_living_situation).to eq(118)
      expect(cls.form_processor).to be_nil # CLS is not the owner, so it does not have a FormProcessor
    end

    it 'updates existing CustomCaseNote and related CurrentLivingSituation' do
      # Run once to generate the records
      record, = submit_form(input)
      case_note = Hmis::Hud::CustomCaseNote.find(record['id'])
      cls = case_note.form_processor.current_living_situation
      expect(cls).to be_present

      # Submit another form to update the same record with different values
      second_input = input.merge(
        record_id: case_note.id.to_s,
        hud_values: {
          'content' => 'note updated',
          'CurrentLivingSituation.currentLivingSituation' => 'DATA_NOT_COLLECTED', # 99
        },
      )

      expect do
        submit_form(second_input)
      end.to not_change(Hmis::Form::FormProcessor, :count).
        and not_change(Hmis::Hud::CustomCaseNote, :count).
        and not_change(Hmis::Hud::CurrentLivingSituation, :count)

      case_note.reload
      cls.reload
      expect(case_note.form_processor.current_living_situation).to eq(cls)
      expect(case_note.content).to eq('note updated')
      expect(cls.form_processor).to be_nil
      expect(cls.current_living_situation).to eq(99)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
