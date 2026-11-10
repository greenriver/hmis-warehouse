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
    AppConfigProperty.create!(key: 'external_forms/presign_url', value: 'http://example.com')
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation PublishExternalForm($id: ID!) {
        publishExternalForm(id: $id) {
          formIdentifier {
            displayVersion {
              id
              externalFormLastPublishedAt
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  def errors_for(result)
    result.dig('data', 'publishExternalForm', 'errors').map { |e| e['fullMessage'] }
  end

  it 'publishes the form to its public URL' do
    expect do
      response, result = post_graphql(id: external_form.id) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(errors_for(result)).to be_empty
      expect(result.dig('data', 'publishExternalForm', 'formIdentifier', 'displayVersion', 'externalFormLastPublishedAt')).to be_present
    end.to change(external_form.external_form_publications, :count).by(1)

    expect(external_form.external_form_publications.sole.object_key).to eq('pit')
  end

  describe 'externalFormPublicUrl' do
    let(:query) do
      <<~GRAPHQL
        query GetFormIdentifierDetails($identifier: String!) {
          formIdentifier(identifier: $identifier) {
            displayVersion {
              id
              externalFormPublicUrl
            }
          }
        }
      GRAPHQL
    end

    before(:each) do
      allow(GrdaWarehouse::RemoteCredentials::S3).to receive(:for_active_slug).with('public_bucket').and_return(double(bucket: 'public-bucket'))
    end

    def public_url
      response, result = post_graphql(identifier: external_form.identifier) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'formIdentifier', 'displayVersion', 'externalFormPublicUrl')
    end

    def publish(definition)
      _response, result = post_graphql(id: definition.id) { mutation }
      expect(errors_for(result)).to be_empty
    end

    it 'is nil until the form is published to its public URL' do
      expect(public_url).to be_nil
      publish(external_form)
      expect(public_url).to eq('https://public-bucket.s3.amazonaws.com/pit')
    end

    it 'is present when an older version was published but the current one was not' do
      publish(external_form)
      external_form.update!(status: Hmis::Form::Definition::RETIRED)
      create :hmis_external_form_definition, identifier: external_form.identifier, version: external_form.version + 1, status: Hmis::Form::Definition::PUBLISHED, external_form_object_key: 'pit', data_source: ds1

      expect(public_url).to eq('https://public-bucket.s3.amazonaws.com/pit')
    end

    it 'is nil when the External Form Key changed since the last publish' do
      publish(external_form)
      external_form.update!(external_form_object_key: 'pit-2026')

      expect(public_url).to be_nil
    end
  end

  it 'returns an error when the form has no External Form Key' do
    external_form.update!(external_form_object_key: nil)
    expect do
      response, result = post_graphql(id: external_form.id) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(errors_for(result)).to contain_exactly('Set the External Form Key before publishing to the public URL.')
    end.not_to change(HmisExternalApis::ExternalForms::FormPublication, :count)
  end

  it 'raises when the form content is invalid, since it is validated when the form is published' do
    duplicate_item = { 'type' => 'STRING', 'link_id' => 'your_name', 'text' => 'Your Name' }
    external_form.update_columns(definition: { 'item' => [duplicate_item, duplicate_item] })
    expect do
      expect_gql_error post_graphql(id: external_form.id) { mutation }, message: 'cannot publish form with errors'
    end.not_to change(HmisExternalApis::ExternalForms::FormPublication, :count)
  end

  it 'returns an error when external forms are not set up' do
    allow(HmisExternalApis::ExternalForms::Config).to receive(:validate_external_forms_setup).and_return(['public bucket'])
    allow(Rails.env).to receive(:production?).and_return(true)
    expect do
      response, result = post_graphql(id: external_form.id) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(errors_for(result)).to contain_exactly('Could not publish to the public URL')
    end.not_to change(HmisExternalApis::ExternalForms::FormPublication, :count)
  end

  it 'only publishes External Forms' do
    other_form = create :hmis_form_definition, status: Hmis::Form::Definition::PUBLISHED, data_source: ds1
    expect_gql_error post_graphql(id: other_form.id) { mutation }, message: 'only External Forms can be published to a public URL'
  end

  it 'only publishes published versions' do
    external_form.update!(status: Hmis::Form::Definition::DRAFT)
    expect_gql_error post_graphql(id: external_form.id) { mutation }, message: 'only published forms can be published to a public URL'
  end

  it 'requires permission to publish the form' do
    remove_permissions(access_control, :can_manage_forms, :can_administrate_config)
    expect_access_denied post_graphql(id: external_form.id) { mutation }
    expect(external_form.external_form_publications).to be_empty
  end
end
