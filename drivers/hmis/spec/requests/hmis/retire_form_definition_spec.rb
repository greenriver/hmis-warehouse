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
  let!(:external_form) { create :hmis_external_form_definition, status: Hmis::Form::Definition::PUBLISHED, external_form_object_key: 'pit', data_source: ds1 }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation RetireFormDefinition($id: ID!) {
        retireFormDefinition(id: $id) {
          formIdentifier {
            identifier
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'retires the published version' do
    response, result = post_graphql(id: external_form.id) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'retireFormDefinition', 'errors')).to be_empty
    expect(external_form.reload.status).to eq(Hmis::Form::Definition::RETIRED)
    expect(Hmis::Form::Definition.where(identifier: external_form.identifier).published).to be_empty
  end

  it 'does not retire a form that has a draft' do
    create :hmis_external_form_definition, identifier: external_form.identifier, version: external_form.version + 1, status: Hmis::Form::Definition::DRAFT, external_form_object_key: 'pit', data_source: ds1
    response, result = post_graphql(id: external_form.id) { mutation }
    expect(response.status).to eq(200), result.inspect
    errors = result.dig('data', 'retireFormDefinition', 'errors')
    expect(errors.map { |e| e['fullMessage'] }).to contain_exactly(start_with('This form has an unpublished draft'))
    expect(external_form.reload.status).to eq(Hmis::Form::Definition::PUBLISHED)
  end

  it 'only retires published versions' do
    draft = create :hmis_form_definition, status: Hmis::Form::Definition::DRAFT, data_source: ds1
    expect_gql_error post_graphql(id: draft.id) { mutation }, message: 'only published forms can be retired'
  end

  it 'only retires External Forms' do
    project_form = create :hmis_form_definition, role: :PROJECT, status: Hmis::Form::Definition::PUBLISHED, data_source: ds1
    expect_gql_error post_graphql(id: project_form.id) { mutation }, message: 'only External Forms can be retired'
    expect(project_form.reload.status).to eq(Hmis::Form::Definition::PUBLISHED)
  end

  it 'requires permission to publish the form' do
    remove_permissions(access_control, :can_manage_forms, :can_administrate_config)
    expect_access_denied post_graphql(id: external_form.id) { mutation }
    expect(external_form.reload.status).to eq(Hmis::Form::Definition::PUBLISHED)
  end

  it 'does not retire forms managed in version control' do
    external_form.update!(managed_in_version_control: true)
    expect_access_denied post_graphql(id: external_form.id) { mutation }
  end
end
