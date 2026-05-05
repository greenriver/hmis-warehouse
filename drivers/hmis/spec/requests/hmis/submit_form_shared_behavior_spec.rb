# frozen_string_literal: true

# Consolidated spec for generic SubmitForm behavior
#
# This file uses the 'PROJECT' role as an example, to test generic behavior that is shared across all roles.
#
# Role-specific behavior (required fields, validations, permissions, etc.) should be tested in each
# submit_form_*_spec.rb file for that role.

require 'rails_helper'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/submit_form_spec_helpers'

RSpec.describe 'SubmitForm shared behavior', type: :request do
  include_context 'hmis base setup'
  include_context 'hmis json forms seed'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  # use PROJECT as an example; the behavior tested here applies to all roles
  let(:definition) { Hmis::Form::Definition.find_by(role: :PROJECT) }
  let(:hud_values) do
    {
      'projectName' => 'Test Project',
      'operatingStartDate' => '2023-01-13',
      'projectType' => 'ES_NBN',
      'continuumProject' => 'NO',
    }
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      organization_id: o1.id,
      confirmed: false,
    }
  end

  shared_examples 'submit form fails when form definition is draft' do
    it 'fails when form definition is draft' do
      draft = create(:hmis_form_definition, version: definition.version + 1, status: Hmis::Form::Definition::DRAFT, identifier: definition.identifier)
      expect_gql_error submit_form(input.merge(form_definition_id: draft.id), expect_raise: true), message: /status draft is invalid/
    end
  end

  shared_examples 'submit form creates form processor' do
    it 'creates a form processor' do
      record, _errors = submit_form(input)
      owner = definition.owner_class.find(record['id'])
      expect(Hmis::Form::FormProcessor.where(owner: owner).count).to eq(1)
      expect(owner.form_processor).to be_present
      expect(owner.form_processor.definition).to eq(definition)
    end
  end

  context 'when creating a new record' do
    it_behaves_like 'submit form creates form processor'
    it_behaves_like 'submit form fails when form definition is draft'

    it 'fails when required field is missing' do
      bad_values = hud_values.merge('projectName' => nil)
      bad_input = input.merge(
        hud_values: bad_values,
        values: hud_values_to_values_by_link_id(bad_values),
      )

      expect_validation_error(
        bad_input,
        exact: false,
        type: 'required',
        attribute: 'projectName',
        severity: 'error',
      )
    end
  end

  context 'when updating an existing record' do
    let!(:input) { super().merge(record_id: p1.id) }

    it_behaves_like 'submit form fails when form definition is draft'

    context 'when record does not have form processor' do
      it_behaves_like 'submit form creates form processor'
    end

    context 'when record already has form processor' do
      let!(:retired_definition) { create(:hmis_form_definition, version: definition.version - 1, status: Hmis::Form::Definition::RETIRED, identifier: definition.identifier) }
      let!(:form_processor) { create(:hmis_form_processor, owner: p1, definition: retired_definition) }

      it 'updates existing form processor' do
        form_processor = p1.form_processor
        expect do
          submit_form(input)
          form_processor.reload
        end.to change(form_processor, :definition).from(retired_definition).to(definition).
          and not_change(Hmis::Form::FormProcessor, :count)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
