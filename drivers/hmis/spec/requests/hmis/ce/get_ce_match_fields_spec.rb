# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'ceMatchFields query', type: :request do
  include_context 'hmis base setup'

  before { allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true) }

  let(:query) do
    <<~GRAPHQL
      query GetCeMatchFields($fieldSource: CeMatchRuleFieldSource!) {
        ceMatchFields(fieldSource: $fieldSource) {
          key
          label
          description
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

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_administrate_coordinated_entry]) }

  before(:each) { hmis_login(user) }

  def query_fields(field_source)
    response, result = post_graphql(fieldSource: field_source) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceMatchFields')
  end

  it 'exposes every registered PSDE field' do
    fields = query_fields('PSDE')

    expect(fields.map { |field| field['key'] }).
      to match_array(Hmis::Ce::Match::Expression::PsdeFieldRegistry::ALL.map(&:key))
  end

  it 'adapts registered PSDE fields into CE match field metadata' do
    fields = query_fields('PSDE')

    # The psde.* namespace is retained in expressionField but stripped from key,
    # registry value types map onto the item types the rule editor consumes, and
    # PSDE fields never carry pick lists.
    expect(fields).to include(
      {
        'key' => 'total_monthly_income',
        'label' => 'Total Monthly Income',
        'description' => Hmis::Ce::Match::Expression::PsdeFieldRegistry::TOTAL_MONTHLY_INCOME.description,
        'itemType' => 'INTEGER',
        'multiple' => false,
        'expressionField' => 'psde.total_monthly_income',
        'pickListReference' => nil,
        'pickListOptions' => nil,
      },
      {
        'key' => 'mental_health_disorder',
        'label' => 'Mental Health Disorder',
        'description' => Hmis::Ce::Match::Expression::PsdeFieldRegistry::MENTAL_HEALTH_DISORDER.description,
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'psde.mental_health_disorder',
        'pickListReference' => nil,
        'pickListOptions' => nil,
      },
      {
        'key' => 'hiv_aids_values_in_window',
        'label' => 'HIV/AIDS (all values in window)',
        'description' => Hmis::Ce::Match::Expression::PsdeFieldRegistry::HIV_AIDS_VALUES_IN_WINDOW.description,
        'itemType' => 'BOOLEAN',
        'multiple' => true,
        'expressionField' => 'psde.hiv_aids_values_in_window',
        'pickListReference' => nil,
        'pickListOptions' => nil,
      },
    )
  end

  it 'exposes every registered client field' do
    fields = query_fields('CLIENT')

    expect(fields.map { |field| field['key'] }).
      to match_array(Hmis::Ce::Match::Expression::ClientFieldMap::Fields::ALL.map { |field| field.key.to_s })
  end

  it 'adapts client fields into CE match field metadata' do
    fields = query_fields('CLIENT')

    # Client fields carry no namespace prefix, and unlike PSDE fields they can
    # reference a pick list, which drives the CHOICE item type, and can be
    # multiple.
    expect(fields).to include(
      hash_including(
        'key' => 'current_age',
        'description' => Hmis::Ce::Match::Expression::ClientFieldMap::Fields::CURRENT_AGE.description,
        'itemType' => 'INTEGER',
        'multiple' => false,
        'expressionField' => 'current_age',
        'pickListReference' => nil,
      ),
      hash_including(
        'key' => 'veteran_status',
        'itemType' => 'CHOICE',
        'multiple' => false,
        'expressionField' => 'veteran_status',
        'pickListReference' => 'NoYesReasonsForMissingData',
        'pickListOptions' => nil,
      ),
      hash_including(
        'key' => 'open_referral_project_types',
        'itemType' => 'CHOICE',
        'multiple' => true,
        'expressionField' => 'open_referral_project_types',
        'pickListReference' => 'ProjectType',
      ),
    )
  end

  it 'returns an error for custom data element fields, which are scoped to a form' do
    expect_gql_error(
      post_graphql(fieldSource: 'CUSTOM_DATA_ELEMENT') { query },
      message: 'Unsupported CE match field source',
    )
  end

  context 'without can_administrate_coordinated_entry permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_coordinated_entry) }

    it 'returns an error' do
      expect_gql_error(post_graphql(fieldSource: 'PSDE') { query }, message: 'access denied')
    end
  end
end
