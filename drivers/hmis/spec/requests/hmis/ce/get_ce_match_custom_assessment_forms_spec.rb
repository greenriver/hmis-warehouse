# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'ceMatchCustomAssessmentForms query', type: :request do
  include_context 'hmis base setup'

  let(:query) do
    <<~GRAPHQL
      query GetCeMatchCustomAssessmentForms {
        ceMatchCustomAssessmentForms {
          identifier
          title
        }
      }
    GRAPHQL
  end

  let(:fields_query) do
    <<~GRAPHQL
      query GetCeMatchCustomAssessmentFields($formDefinitionIdentifier: String!) {
        ceMatchCustomAssessmentFields(formDefinitionIdentifier: $formDefinitionIdentifier) {
          key
          label
          itemType
          multiple
          expressionField
          pickListReference
          pickListOptions {
            code
            label
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_administrate_config, :can_manage_forms, :can_configure_data_collection]) }

  before(:each) { hmis_login(user) }

  def query_custom_assessment_forms
    response, result = post_graphql { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceMatchCustomAssessmentForms')
  end

  def query_custom_assessment_fields(identifier)
    response, result = post_graphql(formDefinitionIdentifier: identifier) { fields_query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceMatchCustomAssessmentFields')
  end

  let!(:published_form) do
    create(
      :hmis_form_definition,
      identifier: 'score_assessment',
      title: 'Score Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :published,
      version: 2,
      data_source: ds1,
      generate_cdeds: true,
      definition: {
        'item' => [
          {
            'type' => 'CHOICE',
            'link_id' => 'score_q',
            'text' => 'Score',
            'pick_list_options' => [
              { 'code' => 'high', 'label' => 'High' },
              { 'code' => 'medium', 'label' => 'Medium' },
            ],
            'mapping' => { 'custom_field_key' => 'score' },
          },
          {
            'type' => 'GROUP',
            'link_id' => 'group',
            'text' => 'Group',
            'item' => [
              {
                'type' => 'BOOLEAN',
                'link_id' => 'nested_q',
                'text' => 'Nested Field',
                'mapping' => { 'custom_field_key' => 'nested_field' },
              },
            ],
          },
          {
            'type' => 'FILE',
            'link_id' => 'upload_q',
            'text' => 'Upload',
            'mapping' => { 'custom_field_key' => 'upload' },
          },
        ],
      },
    )
  end

  let!(:older_score_form) do
    create(
      :hmis_form_definition,
      identifier: 'score_assessment',
      title: 'Score Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :retired,
      version: 1,
      data_source: ds1,
      definition: {
        'item' => [
          {
            'type' => 'CHOICE',
            'link_id' => 'score_q',
            'text' => 'Score',
            'pick_list_options' => [
              { 'code' => 'medium', 'label' => 'Medium' },
              { 'code' => 'low', 'label' => 'Low' },
            ],
            'mapping' => { 'custom_field_key' => 'score' },
          },
        ],
      },
    )
  end

  let!(:draft_score_form) do
    create(
      :hmis_form_definition,
      identifier: 'score_assessment',
      title: 'Score Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :draft,
      version: 3,
      data_source: ds1,
      definition: {
        'item' => [
          {
            'type' => 'CHOICE',
            'link_id' => 'score_q',
            'text' => 'Score',
            'pick_list_options' => [
              { 'code' => 'draft', 'label' => 'Draft' },
            ],
            'mapping' => { 'custom_field_key' => 'score' },
          },
        ],
      },
    )
  end

  let!(:retired_form) do
    create(
      :hmis_form_definition,
      identifier: 'retired_assessment',
      title: 'Retired Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :retired,
      version: 1,
      data_source: ds1,
      generate_cdeds: true,
      definition: {
        'item' => [
          {
            'type' => 'BOOLEAN',
            'link_id' => 'retired_q',
            'text' => 'Retired Field',
            'mapping' => { 'custom_field_key' => 'retired_field' },
          },
        ],
      },
    )
  end
  let!(:retired_cded) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'retired_field',
      label: 'Retired Field',
      field_type: :boolean,
      form_definition: retired_form,
      data_source: ds1,
    )
  end

  let!(:draft_only_form) do
    create(
      :hmis_form_definition,
      identifier: 'draft_only_assessment',
      title: 'Draft Only Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :draft,
      version: 1,
      data_source: ds1,
    )
  end
  let!(:draft_only_cded) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'draft_field',
      label: 'Draft Field',
      field_type: :string,
      form_definition: draft_only_form,
      data_source: ds1,
    )
  end

  let!(:other_ds) { create(:hmis_data_source) }
  let!(:other_ds_form) do
    create(
      :hmis_form_definition,
      identifier: 'other_ds_assessment',
      title: 'Other DS Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :published,
      version: 1,
      data_source: other_ds,
    )
  end
  let!(:other_ds_cded) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'other_field',
      label: 'Other Field',
      field_type: :string,
      form_definition: other_ds_form,
      data_source: other_ds,
    )
  end

  # CDED is the source of truth, in case it differs from the form item JSON
  let!(:score_cded_override) do
    Hmis::Hud::CustomDataElementDefinition.find_by!(
      data_source: ds1,
      form_definition_identifier: 'score_assessment',
      key: 'score',
    ).tap { |cded| cded.update!(label: 'CDED Score Label', repeats: true) }
  end

  it 'returns published and retired custom assessment forms in the user data source' do
    forms = query_custom_assessment_forms

    expect(forms.pluck('identifier').sort).to eq(['retired_assessment', 'score_assessment'].sort)
  end

  it 'does not resolve fields for every form in the form list query' do
    3.times do |idx|
      create(
        :hmis_form_definition,
        identifier: "performance_assessment_#{idx}",
        title: "Performance Assessment #{idx}",
        role: :CUSTOM_ASSESSMENT,
        status: :published,
        version: 1,
        data_source: ds1,
        generate_cdeds: true,
        definition: {
          'item' => [
            {
              'type' => 'STRING',
              'link_id' => "performance_q_#{idx}",
              'text' => "Performance Field #{idx}",
              'mapping' => { 'custom_field_key' => "performance_field_#{idx}" },
            },
          ],
        },
      )
    end

    expect do
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect
    end.to make_database_queries(count: 5..15)
  end

  it 'returns fields for one selected custom assessment and excludes file/json-backed fields' do
    fields = query_custom_assessment_fields('score_assessment')

    expect(fields).to contain_exactly(
      hash_including(
        'key' => 'score',
        'label' => 'CDED Score Label',
        'itemType' => 'CHOICE',
        'multiple' => true,
        'expressionField' => 'cde.custom_assessment.score',
        'pickListReference' => nil,
      ),
      hash_including(
        'key' => 'nested_field',
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'cde.custom_assessment.nested_field',
        'pickListReference' => nil,
        'pickListOptions' => nil,
      ),
    )
  end

  it 'sets expressionField to cde.custom_assessment.{key} for CDED-backed fields' do
    item = query_custom_assessment_fields('retired_assessment').first

    expect(item['expressionField']).to eq('cde.custom_assessment.retired_field')
  end

  it 'falls back to CDED field type when form item metadata is missing' do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'missing_form_item',
      label: 'Missing Form Item',
      field_type: :integer,
      form_definition: published_form,
      data_source: ds1,
    )

    item = query_custom_assessment_fields('score_assessment').find { |field| field['key'] == 'missing_form_item' }

    expect(item).to include(
      'label' => 'Missing Form Item',
      'itemType' => 'INTEGER',
      'multiple' => false,
      'expressionField' => 'cde.custom_assessment.missing_form_item',
      'pickListReference' => nil,
      'pickListOptions' => nil,
    )
  end

  it 'unions pick list options from published and retired form versions but not drafts' do
    score_field = query_custom_assessment_fields('score_assessment').find { |field| field['key'] == 'score' }

    expect(score_field['pickListOptions']).to contain_exactly(
      hash_including('code' => 'high', 'label' => 'High'),
      hash_including('code' => 'medium', 'label' => 'Medium'),
      hash_including('code' => 'low', 'label' => 'Low'),
    )
    expect(score_field['pickListOptions'].pluck('code')).not_to include('draft')
  end

  it 'does not return fields for draft-only or other data source forms' do
    expect(query_custom_assessment_fields('draft_only_assessment')).to be_empty
    expect(query_custom_assessment_fields('other_ds_assessment')).to be_empty
  end

  context 'without can_administrate_config permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_config) }

    it 'returns an error for the form list query' do
      expect_gql_error(post_graphql { query }, message: 'access denied')
    end

    it 'returns an error for the field list query' do
      expect_gql_error(post_graphql(formDefinitionIdentifier: 'score_assessment') { fields_query }, message: 'access denied')
    end
  end
end
