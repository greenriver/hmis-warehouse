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
    assign_viewable(edit_access_group, p1, hmis_user)
    c1.update({ dob: Date.today - 18.years, ssn: '123456789' })
  end

  let!(:f1) { create :file, client: c1, blob: blob, user: hmis_user, tags: [tag] }
  let!(:f2) { create :file, client: c1, blob: blob, user: hmis_user, tags: [tag], confidential: true }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }

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

  let(:permissions_query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          ssn
          dob
          age
          access {
            id
            canEditClient
            canDeleteClient
            canViewDob
            canViewFullSsn
            canViewPartialSsn
            canEditEnrollments
            canDeleteEnrollments
            canViewEnrollmentDetails
            canDeleteAssessments
            canManageAnyClientFiles
            canManageOwnClientFiles
            canViewAnyConfidentialClientFiles
            canViewAnyNonconfidentialClientFiles
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

  it 'should return client if can view clients and client is unenrolled' do
    e1.destroy!
    response, result = post_graphql(id: c1.id) { query }
    expect(response.status).to eq 200
    expect(result.dig('data', 'client')).to be_present
  end

  it 'should return no client if not viewable due to being enrolled at a project the user doesn\'t have view permissions for' do
    e1.destroy!
    p2 = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1)
    create(:hmis_hud_enrollment, data_source: ds1, project: p2, client: c1, user: u1)

    response, result = post_graphql(id: c1.id) { query }
    expect(response.status).to eq 200
    expect(result.dig('data', 'client')).to be_nil
  end

  it 'should return no client if not viewable due to no permissions' do
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
    remove_permissions(hmis_user, :can_manage_own_client_files, :can_view_any_confidential_client_files, :can_view_any_nonconfidential_client_files)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('files' => { 'nodes' => be_empty })
  end

  it 'should return only non-confidential files if not allowed to see confidential' do
    remove_permissions(hmis_user, :can_manage_own_client_files, :can_view_any_confidential_client_files)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('files' => { 'nodes' => contain_exactly(include('id' => f1.id.to_s)) })
  end

  it 'should return user\' own files if allowed to manage own files, regardless of any view permissions' do
    remove_permissions(hmis_user, :can_view_any_confidential_client_files, :can_view_any_nonconfidential_client_files)
    create :file, client: c1, blob: blob, user: nil, tags: [tag]
    expect(Hmis::File.count).to eq(3)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client', 'files', 'nodes')).to contain_exactly(include('id' => f1.id.to_s), include('id' => f2.id.to_s))
  end

  describe 'permissions base tests' do
    before(:each) do
      assign_viewable(view_access_group, ds1, hmis_user)
    end

    def expected_hash_from_role(role)
      role.attributes.entries.select { |k, _v| k.match(/^can_/) }.map { |k, v| [k.camelize(:lower), v] }.to_h
    end

    def check_client_access_with_role(hash, role)
      expect(hash).to include(
        'canEditClient' => role.can_edit_clients,
        'canDeleteClient' => role.can_delete_clients,
        'canViewDob' => role.can_view_dob,
        'canViewFullSsn' => role.can_view_full_ssn,
        'canViewPartialSsn' => role.can_view_partial_ssn,
        'canEditEnrollments' => role.can_edit_enrollments,
        'canDeleteEnrollments' => role.can_delete_enrollments,
        'canViewEnrollmentDetails' => role.can_view_enrollment_details,
        'canDeleteAssessments' => role.can_delete_assessments,
        'canManageAnyClientFiles' => role.can_manage_any_client_files,
        'canManageOwnClientFiles' => role.can_manage_own_client_files,
        'canViewAnyConfidentialClientFiles' => role.can_view_any_confidential_client_files,
        'canViewAnyNonconfidentialClientFiles' => role.can_view_any_nonconfidential_client_files,
      )
    end

    it 'should have global permissions for an unenrolled client' do
      e1.destroy!
      _response, result = post_graphql(id: c1.id) { permissions_query }
      check_client_access_with_role(result.dig('data', 'client', 'access'), edit_access_group.roles.first)
    end

    it 'should have edit permissions for a client enrolled at a project with user edit access' do
      _response, result = post_graphql(id: c1.id) { permissions_query }
      check_client_access_with_role(result.dig('data', 'client', 'access'), edit_access_group.roles.first)
    end

    it 'should only have view permissions for a client enrolled at a project without user edit access' do
      e1.destroy!
      p2 = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1)
      create(:hmis_hud_enrollment, data_source: ds1, project: p2, client: c1, user: u1)
      _response, result = post_graphql(id: c1.id) { permissions_query }
      check_client_access_with_role(result.dig('data', 'client', 'access'), view_access_group.roles.first)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
