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
  let!(:fd1) { create :hmis_form_definition, status: Hmis::Form::Definition::DRAFT }
  let!(:fd2) { create :hmis_form_definition }

  let!(:fd3_v0) { create :hmis_form_definition, identifier: 'fd3', version: 0, status: Hmis::Form::Definition::RETIRED }
  let!(:fd3_v1) { create :hmis_form_definition, identifier: 'fd3', version: 1, status: Hmis::Form::Definition::PUBLISHED }
  let!(:fd3_v2) { create :hmis_form_definition, identifier: 'fd3', version: 2, status: Hmis::Form::Definition::DRAFT }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation PublishFormDefinition($id: ID!) {
        publishFormDefinition(id: $id) {
          newlyPublished {
            id
            identifier
            status
          }
          newlyRetired {
            id
            identifier
            status
          }
        }
      }
    GRAPHQL
  end

  it 'should work when there is just one draft to convert to published' do
    response, result = post_graphql(id: fd1.id) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'publishFormDefinition', 'newlyPublished', 'status')).to eq(Hmis::Form::Definition::PUBLISHED)
    expect(
      Hmis::Form::Definition.where(
        identifier: fd1.identifier,
        status: Hmis::Form::Definition::DRAFT,
      ),
    ).to be_empty
  end

  it 'should fail if the definition is not a draft' do
    response, result = post_graphql(id: fd2.id) { mutation }
    expect(response.status).to eq(500), result.inspect
    expect(result.dig('errors', 0, 'message')).to eq('only draft forms can be published')
  end

  it 'should retire the previous published version' do
    response, result = post_graphql(id: fd3_v2.id) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'publishFormDefinition', 'newlyPublished', 'status')).to eq(Hmis::Form::Definition::PUBLISHED)
    expect(result.dig('data', 'publishFormDefinition', 'newlyRetired', 'status')).to eq(Hmis::Form::Definition::RETIRED)

    expect(
      Hmis::Form::Definition.where(
        identifier: fd3_v2.identifier,
        status: Hmis::Form::Definition::DRAFT,
      ),
    ).to be_empty

    expect(
      Hmis::Form::Definition.where(
        identifier: fd3_v2.identifier,
        status: Hmis::Form::Definition::PUBLISHED,
      ).first.id,
    ).to eq(fd3_v2.id)

    expect(
      Hmis::Form::Definition.where(
        identifier: fd3_v2.identifier,
        status: Hmis::Form::Definition::RETIRED,
      ).last.id,
    ).to eq(fd3_v1.id), 'the one that was previously published should now be retired'
  end
end
