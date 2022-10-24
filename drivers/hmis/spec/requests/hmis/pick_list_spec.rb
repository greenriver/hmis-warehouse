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
          initialSelected
        }
      }
    GRAPHQL
  end

  it 'returns CoC pick list' do
    response, result = post_graphql(pick_list_type: 'COC') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to be_present
  end

  it 'returns project pick list' do
    response, result = post_graphql(pick_list_type: 'PROJECT') { query }
    expect(response.status).to eq 200
    puts Hmis::Hud::Project.viewable_by(hmis_user).count
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
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
