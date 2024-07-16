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
  let!(:string_cded) { create :hmis_custom_data_element_definition_for_housing_preference, data_source: ds1 }
  let!(:definition_json) do
    {
      'item': [
        {
          'type': 'GROUP',
          'link_id': 'group_1',
          'item': [
            {
              'type': 'DATE',
              'link_id': 'linkid_date',
              'required': true,
              'warn_if_empty': false,
              'text': 'Assessment Date',
              'assessment_date': true,
              'mapping': { 'field_name': 'assessmentDate' },
            },
            {
              'type': 'STRING',
              'link_id': 'housing_preference',
              'required': false,
              'warn_if_empty': false,
              'text': string_cded.label,
              'mapping': { 'custom_field_key': string_cded.key },
            },
            {
              'type': 'INTEGER',
              'link_id': 'linkid_num',
              'required': false,
              'warn_if_empty': true,
              'text': 'Ranking',
              # no mapping, publish should generate one
            },
            {
              'type': 'DISPLAY',
              'link_id': 'linkid_display',
              'text': 'Instructional text',
            },
          ],
        },
      ],
    }
  end
  let!(:fd1) { create :hmis_form_definition, definition: definition_json, status: Hmis::Form::Definition::DRAFT, role: :CUSTOM_ASSESSMENT }
  let!(:fd2) { create :hmis_form_definition }

  let!(:fd3_v0) { create :hmis_form_definition, identifier: 'fd3', version: 0, status: Hmis::Form::Definition::RETIRED, role: :CUSTOM_ASSESSMENT }
  let!(:fd3_v1) { create :hmis_form_definition, identifier: 'fd3', version: 1, status: Hmis::Form::Definition::PUBLISHED, role: :CUSTOM_ASSESSMENT }
  let!(:fd3_v2) { create :hmis_form_definition, identifier: 'fd3', version: 2, status: Hmis::Form::Definition::DRAFT, role: :CUSTOM_ASSESSMENT }

  let!(:non_assessment_form) { create :hmis_form_definition, status: Hmis::Form::Definition::DRAFT }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation PublishFormDefinition($id: ID!) {
        publishFormDefinition(id: $id) {
          formIdentifier {
            identifier
            publishedVersion {
              id
            }
          }
        }
      }
    GRAPHQL
  end

  it 'should work when there is just one draft to convert to published' do
    response, result = post_graphql(id: fd1.id) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'publishFormDefinition', 'formIdentifier', 'publishedVersion', 'id')).to eq(fd1.id.to_s)
    expect(fd1.reload.status).to eq(Hmis::Form::Definition::PUBLISHED)
    expect(Hmis::Form::Definition.where(identifier: fd1.identifier).draft).to be_empty
  end

  it 'should fail if the definition is not a draft' do
    expect_gql_error post_graphql(id: fd2.id) { mutation }, message: 'only draft forms can be published'
  end

  it 'should fail if the user lacks permission' do
    remove_permissions(access_control, :can_administrate_config)
    expect_access_denied post_graphql(id: non_assessment_form.id) { mutation }

    remove_permissions(access_control, :can_manage_forms)
    expect_access_denied post_graphql(id: fd2.id) { mutation }
  end

  it 'should retire the previous published version' do
    response, result = post_graphql(id: fd3_v2.id) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'publishFormDefinition', 'formIdentifier', 'publishedVersion', 'id')).to eq(fd3_v2.id.to_s)

    expect(fd3_v2.reload.status).to eq(Hmis::Form::Definition::PUBLISHED)
    expect(fd3_v1.reload.status).to eq(Hmis::Form::Definition::RETIRED), 'the one that was previously published should now be retired'
    expect(Hmis::Form::Definition.where(identifier: fd3_v2.identifier).draft).to be_empty
  end

  it 'should generate CustomDataElementDefinitions where missing' do
    expect do
      response, result = post_graphql(id: fd1.id) { mutation }
      expect(response.status).to eq(200), result.inspect
    end.to change(Hmis::Hud::CustomDataElementDefinition, :count).by(1)

    # Check that the new CustomDataElementDefinition was created correctly
    new_cded = Hmis::Hud::CustomDataElementDefinition.for_custom_assessments.find_by(label: 'Ranking')
    expect(new_cded).to be_present
    expect(new_cded.attributes).to include(
      'field_type' => 'integer',
      'key' => "#{fd1.identifier}_linkid_num",
      'label' => 'Ranking',
      'repeats' => false,
      'show_in_summary' => false,
      'form_definition_identifier' => fd1.identifier,
    )

    # Check that FormDefinition was updated with the new CustomDataElementDefinition key
    expect(fd1.reload.link_id_item_hash['linkid_num'].mapping&.custom_field_key).to eq(new_cded.key)
  end

  it 'should ensure that the CustomDataElementDefinition key is unique' do
    conflicting_cded = create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: "#{fd1.identifier}_linkid_num", data_source: ds1)

    expect do
      response, result = post_graphql(id: fd1.id) { mutation }
      expect(response.status).to eq(200), result.inspect
    end.to change(Hmis::Hud::CustomDataElementDefinition, :count).by(1)

    # Check that the new CustomDataElementDefinition has unique key
    new_cded = Hmis::Hud::CustomDataElementDefinition.for_custom_assessments.find_by(label: 'Ranking')
    expect(new_cded).to be_present
    expect(new_cded.key).to eq("#{conflicting_cded.key}_2") # unique key

    # Check that FormDefinition was updated with the new CustomDataElementDefinition key
    expect(fd1.reload.link_id_item_hash['linkid_num'].mapping&.custom_field_key).to eq(new_cded.key)
  end
end
