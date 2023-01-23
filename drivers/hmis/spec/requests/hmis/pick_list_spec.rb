require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:pc1) { create :hmis_hud_project_coc, data_source_id: ds1.id, project: p1, coc_code: 'MA-500' }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, o1.as_warehouse, hmis_user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!, $relationId: ID) {
        pickList(pickListType: $pickListType, relationId: $relationId) {
          code
          label
          secondaryLabel
          groupLabel
          groupCode
          initialSelected
        }
      }
    GRAPHQL
  end

  before do
    # Mock RELEVANT_COC_STATE response
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('RELEVANT_COC_STATE').and_return('VT')
  end

  it 'returns CoC pick list' do
    response, result = post_graphql(pick_list_type: 'COC') { query }
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options[0]['code']).to be_present
    end
  end

  it 'returns project pick list' do
    response, result = post_graphql(pick_list_type: 'PROJECT') { query }
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options[0]['code']).to eq(p1.id.to_s)
      expect(options[0]['label']).to eq(p1.project_name)
      expect(options[0]['groupLabel']).to eq(o1.organization_name)
    end
  end

  it 'returns organization pick list' do
    response, result = post_graphql(pick_list_type: 'ORGANIZATION') { query }
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options[0]['code']).to eq(o1.id.to_s)
      expect(options[0]['label']).to eq(o1.organization_name)
      expect(options[0]['groupLabel']).to be_nil
    end
  end

  it 'returns grouped living situation pick list' do
    response, result = post_graphql(pick_list_type: 'PRIOR_LIVING_SITUATION') { query }
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options[0]['code']).to eq(Types::HmisSchema::Enums::Hud::LivingSituation.all_enum_value_definitions.find { |v| v.value == 16 }.graphql_name)
      expect(options[0]['label']).to eq(::HudUtility.living_situation(16))
      expect(options[0]['groupCode']).to eq('HOMELESS')
      expect(options[0]['groupLabel']).to eq('Homeless')
    end
  end

  it 'returns CoC pick list for RELEVANT_COC_STATE' do
    response, result = post_graphql(pick_list_type: 'COC') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq('VT-500')
  end

  it 'returns CoC pick list for specified project' do
    response, result = post_graphql(pick_list_type: 'COC', relationId: p1.id.to_s) { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options.length).to eq(1)
    expect(options[0]['code']).to eq(pc1.coc_code)
    expect(options[0]['label']).to include(::HudUtility.cocs[pc1.coc_code])
    expect(options[0]['initialSelected']).to eq(true)
  end

  it 'returns states with RELEVANT_COC_STATE selected' do
    response, result = post_graphql(pick_list_type: 'STATE') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options.detect { |o| o['initialSelected'] }['code']).to eq('VT')
  end

  it 'returns geocodes for RELEVANT_COC_STATE' do
    response, result = post_graphql(pick_list_type: 'GEOCODE') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq('509001')
  end

  it 'returns grouped service type pick list' do
    response, result = post_graphql(pick_list_type: 'SERVICE_TYPE', relationId: e1.id.to_s) { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options.length).to eq(
      Types::HmisSchema::Enums::ServiceTypeProvided.all_enum_value_definitions.reject { |item| item.value.is_a?(Integer) }.count,
    )
    expect(options).to include(
      include(
        'code' => 'PATH_SERVICE__RE_ENGAGEMENT',
        'label' => 'Re-engagement',
        'groupCode' => 'PATH_SERVICE',
        'groupLabel' => 'PATH service',
      ),
    )
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
