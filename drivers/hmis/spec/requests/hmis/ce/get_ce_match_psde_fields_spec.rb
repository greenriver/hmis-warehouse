# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'ceMatchPsdeFields query', type: :request do
  include_context 'hmis base setup'

  before { allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true) }

  let(:query) do
    <<~GRAPHQL
      query GetCeMatchPsdeFields {
        ceMatchPsdeFields {
          key
          label
          itemType
          multiple
          expressionField
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_administrate_coordinated_entry]) }

  before(:each) { hmis_login(user) }

  def query_psde_fields
    response, result = post_graphql { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceMatchPsdeFields')
  end

  it 'returns CE match field metadata for every registered PSDE field' do
    fields = query_psde_fields

    # These expectations verify the adapter's three responsibilities: retaining
    # the psde.* expression namespace, supplying labels, and translating registry
    # value types into the item types consumed by the structured rule editor.
    expect(fields).to contain_exactly(
      {
        'key' => 'total_monthly_income',
        'label' => 'Total Monthly Income',
        'itemType' => 'INTEGER',
        'multiple' => false,
        'expressionField' => 'psde.total_monthly_income',
      },
      {
        'key' => 'mental_health_disorder',
        'label' => 'Mental Health Disorder',
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'psde.mental_health_disorder',
      },
      {
        'key' => 'substance_use_disorder',
        'label' => 'Substance Use Disorder',
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'psde.substance_use_disorder',
      },
      {
        'key' => 'physical_disability',
        'label' => 'Physical Disability',
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'psde.physical_disability',
      },
      {
        'key' => 'developmental_disability',
        'label' => 'Developmental Disability',
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'psde.developmental_disability',
      },
      {
        'key' => 'chronic_health_condition',
        'label' => 'Chronic Health Condition',
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'psde.chronic_health_condition',
      },
      {
        'key' => 'hiv_aids',
        'label' => 'HIV/AIDS',
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'psde.hiv_aids',
      },
      {
        'key' => 'domestic_violence_survivor',
        'label' => 'DV Survivor',
        'itemType' => 'BOOLEAN',
        'multiple' => false,
        'expressionField' => 'psde.domestic_violence_survivor',
      },
    )
  end

  context 'without can_administrate_coordinated_entry permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_coordinated_entry) }

    it 'returns an error' do
      expect_gql_error(post_graphql { query }, message: 'access denied')
    end
  end
end
