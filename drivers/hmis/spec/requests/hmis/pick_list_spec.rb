require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let(:u2) do
    user2 = create(:user).tap { |u| u.add_viewable(ds1) }
    hmis_user2 = Hmis::User.find(user2.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) }
    Hmis::Hud::User.from_user(hmis_user2)
  end
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, organization: o1, data_source: ds1, user: u2 }

  before(:each) do
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
  end

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!) {
        pickList(pickListType: $pickListType) {
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

  it 'returns project pick list' do
    response, result = post_graphql(pick_list_type: 'PROJECT') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq(p1.id.to_s)
    expect(options[0]['label']).to eq(p1.project_name)
    expect(options[0]['groupLabel']).to eq(o1.organization_name)
  end

  it 'returns organization pick list' do
    response, result = post_graphql(pick_list_type: 'ORGANIZATION') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq(o1.id.to_s)
    expect(options[0]['label']).to eq(o1.organization_name)
    expect(options[0]['groupLabel']).to be_nil
  end

  it 'returns grouped living situation pick list' do
    response, result = post_graphql(pick_list_type: 'PRIOR_LIVING_SITUATION') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq(::HUD.homeless_situations(as: :prior).first.to_s)
    expect(options[0]['label']).to eq(::HUD.living_situation(options[0]['code'].to_i))
    expect(options[0]['groupCode']).to eq('HOMELESS')
    expect(options[0]['groupLabel']).to eq('Homeless')
  end

  it 'returns CoC pick list for RELEVANT_COC_STATE' do
    response, result = post_graphql(pick_list_type: 'COC') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq('VT-500')
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
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
