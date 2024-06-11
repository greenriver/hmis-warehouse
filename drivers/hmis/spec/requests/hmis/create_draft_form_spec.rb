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
      mutation CreateDraftForm($identifier: String!) {
        createDraftForm(identifier: $identifier) {
          formIdentifier {
            identifier
            draftVersion {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should fail if a draft already exists for this identifier' do
    response, result = post_graphql(identifier: fd2.identifier) { mutation }
    expect(response.status).to eq(500), result.inspect
    expect(result.dig('errors', 0, 'message')).to eq('not allowed to create draft if one already exists')
  end

  it 'should successfully create a new draft version' do
    response, result = post_graphql(identifier: fd1.identifier) { mutation }
    expect(response.status).to eq(200), result.inspect
    draft_version_result = result.dig('data', 'createDraftForm', 'formIdentifier', 'draftVersion')
    draft_version = Hmis::Form::Definition.where(identifier: fd1.identifier, status: Hmis::Form::Definition::DRAFT).first
    expect(draft_version_result.dig('id')).to eq(draft_version.id.to_s)
    expect(draft_version.version).to eq(fd1.version + 1)
  end
end
