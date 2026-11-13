###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:fd1) { create :hmis_form_definition, status: Hmis::Form::Definition::PUBLISHED, data_source: ds1 }
  let!(:fd2) { create :hmis_form_definition, status: Hmis::Form::Definition::DRAFT, data_source: ds1 }

  # cruft: form with the same identifier exists in a different DS. should be ignored
  let!(:cruft_form) { create(:hmis_form_definition, identifier: fd1.identifier, version: 5) }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateNextDraftFormDefinition($identifier: String!) {
        createNextDraftFormDefinition(identifier: $identifier) {
          formIdentifier {
            identifier
            draftVersion {
              id
            }
          }
        }
      }
    GRAPHQL
  end

  it 'should successfully create a new draft version' do
    response, result = post_graphql(identifier: fd1.identifier) { mutation }
    expect(response.status).to eq(200), result.inspect
    definition_result = result.dig('data', 'createNextDraftFormDefinition', 'formIdentifier', 'draftVersion')
    created_draft = Hmis::Form::Definition.where(identifier: fd1.identifier, status: Hmis::Form::Definition::DRAFT).first
    expect(definition_result.dig('id')).to eq(created_draft.id.to_s)
    expect(created_draft.version).to eq(fd1.version + 1)
  end

  it 'should not create a new draft if a draft already exists for this identifier' do
    response, result = post_graphql(identifier: fd2.identifier) { mutation }
    expect(response.status).to eq(200), result.inspect
    definition = result.dig('data', 'createNextDraftFormDefinition', 'formIdentifier', 'draftVersion')
    expect(definition.dig('id')).to eq(fd2.id.to_s)
  end

  it 'should error if the user lacks permission' do
    remove_permissions(access_control, :can_administrate_config)
    expect_access_denied post_graphql(identifier: fd2.identifier) { mutation }

    fd2.role = 'CUSTOM_ASSESSMENT'
    fd2.save!

    response, result = post_graphql(identifier: fd2.identifier) { mutation }
    expect(response.status).to eq(200), result.inspect

    remove_permissions(access_control, :can_manage_forms)
    expect_access_denied post_graphql(identifier: fd2.identifier) { mutation }
  end

  describe 'retired external forms' do
    let!(:retired_form) { create :hmis_external_form_definition, status: Hmis::Form::Definition::RETIRED, external_form_object_key: 'pit', data_source: ds1 }

    def new_draft_for(identifier)
      response, result = post_graphql(identifier: identifier) { mutation }
      expect(response.status).to eq(200), result.inspect
      Hmis::Form::Definition.find(result.dig('data', 'createNextDraftFormDefinition', 'formIdentifier', 'draftVersion', 'id'))
    end

    it 'keeps the object key when no other form has reused it' do
      expect(new_draft_for(retired_form.identifier).external_form_object_key).to eq('pit')
    end

    it 'leaves the object key off the new draft when another form has reused it' do
      create :hmis_external_form_definition, status: Hmis::Form::Definition::PUBLISHED, external_form_object_key: 'pit', data_source: ds1
      new_draft = new_draft_for(retired_form.identifier)
      expect(new_draft.external_form_object_key).to be_nil
      expect(retired_form.reload.external_form_object_key).to eq('pit')
    end
  end

  it 'should error if the form is managed in version control' do
    fd = create(:hmis_form_definition, managed_in_version_control: true, data_source: ds1)
    expect_access_denied post_graphql(identifier: fd.identifier) { mutation }
  end

  it 'keeps the external form object key on the new draft, so it stays locked across versions' do
    external_form = create :hmis_external_form_definition, status: Hmis::Form::Definition::PUBLISHED, external_form_object_key: 'pit-2027', data_source: ds1
    response, result = post_graphql(identifier: external_form.identifier) { mutation }
    expect(response.status).to eq(200), result.inspect

    new_draft = Hmis::Form::Definition.find(result.dig('data', 'createNextDraftFormDefinition', 'formIdentifier', 'draftVersion', 'id'))
    expect(new_draft.version).to eq(external_form.version + 1)
    expect(new_draft.external_form_object_key).to eq('pit-2027')
  end
end
