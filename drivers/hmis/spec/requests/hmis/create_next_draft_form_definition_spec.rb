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
  let!(:fd1) { create :hmis_form_definition, status: Hmis::Form::Definition::PUBLISHED }
  let!(:fd2) { create :hmis_form_definition, status: Hmis::Form::Definition::DRAFT }

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
end
