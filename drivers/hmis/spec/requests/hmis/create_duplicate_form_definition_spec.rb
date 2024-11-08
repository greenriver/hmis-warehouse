#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, ds1) }

  # Published form to duplicate. Include HUD and Custom fields to ensure correct duplication behavior (removing custom field mappings)
  let!(:published_form) do
    items = [
      { 'link_id': 'clientDob', 'text': 'dob?', 'type': 'DATE', 'mapping': { 'record_type': 'CLIENT', 'field_name': 'dob' } },
      { 'link_id': 'question', 'text': 'what is your name?', 'type': 'STRING', 'mapping': { 'custom_field_key': 'custom_name_field' } },
    ]
    create :hmis_form_definition, status: Hmis::Form::Definition::PUBLISHED, version: 2, definition: { 'item': items }
  end

  # cruft: retired and draft versions of the form, which we expect to be ignored
  let!(:retired_form) { create :hmis_form_definition, status: Hmis::Form::Definition::RETIRED, version: 1, identifier: published_form.identifier, definition: { 'item': [{ 'link_id': 'foo', 'text': 'not the published form', 'type': 'DISPLAY' }] } }
  let!(:draft_form) { create :hmis_form_definition, status: Hmis::Form::Definition::DRAFT, version: 3, identifier: retired_form.identifier, definition: retired_form.definition }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateDuplicateFormDefinition($identifier: String!) {
        createDuplicateFormDefinition(identifier: $identifier) {
          formIdentifier {
            identifier
            displayVersion {
              id
              status
              title
              role
              version
            }
          }
        }
      }
    GRAPHQL
  end

  def perform_mutation
    response, result = post_graphql(identifier: published_form.identifier) { mutation }
    expect(response.status).to eq(200), result.inspect

    # return form that was created
    identifier = result.dig('data', 'createDuplicateFormDefinition', 'formIdentifier', 'identifier')
    Hmis::Form::Definition.where(identifier: identifier).sole
  end

  it 'should successfully create a new draft version' do
    new_fd = nil
    expect do
      new_fd = perform_mutation
    end.to change(Hmis::Form::Definition, :count).by(1).
      and(not_change { published_form.reload.definition })

    expect(new_fd.version).to eq(0)
    expect(new_fd.role).to eq(retired_form.role)
    expect(new_fd.status).to eq(Hmis::Form::Definition::DRAFT)
    expect(new_fd.identifier).to eq("#{published_form.identifier}_copy")

    # Title should be different
    expect(new_fd.title).not_to eq(published_form.title)
    expect(new_fd.title).to include(published_form.title)
    # Ensure custom field mappings were removed
    expect(new_fd.definition['item']).to contain_exactly(
      published_form.definition['item'].first,
      published_form.definition['item'].second.excluding('mapping'), # ensure custom_field_key mapping was removed
    )
  end

  it 'should create unique identifier when there is a conflict' do
    # create dup of expected identifier
    create(:hmis_form_definition, identifier: "#{published_form.identifier}_copy")

    new_fd = nil
    expect do
      new_fd = perform_mutation
    end.to change(Hmis::Form::Definition, :count).by(1).
      and(not_change { published_form.reload.definition })

    expect(new_fd.version).to eq(0)
    expect(new_fd.identifier).to eq("#{published_form.identifier}_copy_2")
  end

  it 'should error if the user lacks permission' do
    remove_permissions(access_control, :can_manage_forms)
    expect_access_denied post_graphql(identifier: published_form.identifier) { mutation }
  end
end
