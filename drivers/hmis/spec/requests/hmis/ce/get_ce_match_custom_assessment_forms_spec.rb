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
          ceMatchItems {
            linkId
            type
            text
            repeats
            pickListReference
            ceMatchExpressionField
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: :can_administrate_config) }

  before(:each) { hmis_login(user) }

  def query_custom_assessment_forms
    response, result = post_graphql { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceMatchCustomAssessmentForms')
  end

  let!(:published_form) do
    create(
      :hmis_form_definition,
      identifier: 'score_assessment',
      title: 'Score Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :published,
      version: 1,
      data_source: ds1,
      generate_cdeds: true,
      definition: {
        'item' => [
          {
            'type' => 'INTEGER',
            'link_id' => 'score_q',
            'text' => 'Score',
            'mapping' => { 'custom_field_key' => 'score' },
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

  let!(:form_without_cdeds) do
    create(
      :hmis_form_definition,
      identifier: 'empty_assessment',
      title: 'Empty Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :published,
      version: 1,
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

  it 'returns published and retired custom assessment forms with usable CDEDs in the user data source' do
    forms = query_custom_assessment_forms

    expect(forms.pluck('identifier')).to eq(['retired_assessment', 'score_assessment'])
    expect(forms.pluck('title')).to eq(['Retired Assessment', 'Score Assessment'])
  end

  it 'returns ceMatchItems as FormItem objects and excludes file/json-backed fields' do
    score_form = query_custom_assessment_forms.find { |form| form['identifier'] == 'score_assessment' }

    expect(score_form['ceMatchItems']).to contain_exactly(
      hash_including(
        'linkId' => 'score_q',
        'type' => 'INTEGER',
        'ceMatchExpressionField' => 'cde.custom_assessment.score',
      ),
    )
  end

  it 'sets ceMatchExpressionField to cde.custom_assessment.{key} for CDED-backed items' do
    retired_form_result = query_custom_assessment_forms.find { |form| form['identifier'] == 'retired_assessment' }
    item = retired_form_result['ceMatchItems'].first

    expect(item['ceMatchExpressionField']).to eq('cde.custom_assessment.retired_field')
  end

  context 'without can_administrate_config permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_config) }

    it 'returns an error' do
      expect_gql_error(post_graphql { query }, message: 'access denied')
    end
  end
end
