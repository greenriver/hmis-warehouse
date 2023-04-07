###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  include_context 'file upload setup'

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, ds1, hmis_user)
    c1.update({ dob: Date.today - 18.years, ssn: '123456789' })
  end

  let!(:f1) { create :file, client: c1, blob: blob, user: hmis_user, tags: [tag] }
  let!(:f2) { create :file, client: c1, blob: blob, user: hmis_user, tags: [tag], confidential: true }

  let(:query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          ssn
          dob
          age
          files {
            nodes {
              id
            }
          }
        }
      }
    GRAPHQL
  end

  it 'should return client if viewable' do
    response, result = post_graphql(id: c1.id) { query }
    expect(response.status).to eq 200
    expect(result.dig('data', 'client')).to include(
      'id' => c1.id.to_s,
      'ssn' => c1.ssn,
      'dob' => c1.dob.strftime('%F'),
      'age' => c1.age,
      'files' => {
        'nodes' => include(include('id' => f1.id.to_s), include('id' => f2.id.to_s)),
      },
    )
  end

  it 'should return no client if not viewable' do
    remove_permissions(hmis_user, :can_view_clients)
    response, result = post_graphql(id: c1.id) { query }
    expect(response.status).to eq 200
    expect(result.dig('data', 'client')).to be_nil
  end

  it 'should return null DOB if not allowed to see DOB' do
    remove_permissions(hmis_user, :can_view_dob)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('dob' => nil, 'age' => c1.age)
  end

  it 'should return null SSN if not allowed to see SSN' do
    remove_permissions(hmis_user, :can_view_full_ssn, :can_view_partial_ssn)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('ssn' => nil)
  end

  it 'should return null SSN if not allowed to see SSN' do
    remove_permissions(hmis_user, :can_view_full_ssn)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('ssn' => 'XXXXX6789')
  end

  it 'should return no files if not allowed to see any' do
    remove_permissions(hmis_user, :can_view_any_confidential_client_files, :can_view_any_nonconfidential_client_files)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('files' => { 'nodes' => be_empty })
  end

  it 'should return only non-confidential files if not allowed to see confidential' do
    remove_permissions(hmis_user, :can_view_any_confidential_client_files)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('files' => { 'nodes' => contain_exactly(include('id' => f1.id.to_s)) })
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
