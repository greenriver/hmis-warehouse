###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    c1.update({ dob: Date.current - 18.years, ssn: '123456789' })
    create(:hmis_hud_custom_client_contact_point, client: c1, data_source: ds1)
    create(:hmis_hud_custom_client_contact_point, value: 'email@e.mail', system: 'email', client: c1, data_source: ds1)
    create(:hmis_hud_custom_client_address, data_source: ds1, client: c1, line1: '999 Test Ave')
  end

  let!(:f1) { create :file, client: c1, blob: blob, user: hmis_user, tags: [tag] }
  let!(:f2) { create :file, client: c1, blob: blob, user: hmis_user, tags: [tag], confidential: true }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:photo_tag) { create :available_file_tag, consent_form: false, name: 'Client Headshot' }
  let!(:photo) { create :client_file, client: c1.as_warehouse, name: 'Client Headshot Cache', tags: [photo_tag] }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          ssn
          dob
          age
          hudChronic
          user {
            id
            name
          }
          createdBy {
            id
            name
          }
          addresses {
            line1
          }
          phoneNumbers {
            value
            use
            system
          }
          emailAddresses {
            value
            use
            system
          }
          names {
            id
            first
            last
          }
          image {
            id
            contentType
            base64
          }
          files {
            nodes {
              id
              name
              confidential
              redacted
              fileBlobId
              tags
              updatedBy {
                id
              }
              uploadedBy {
                id
              }
              url
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

  describe 'without version history' do
    it 'should have nil users' do
      _response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'client', 'createdBy', 'id')).to be_nil
      expect(result.dig('data', 'client', 'user', 'id')).to be_nil
    end
  end

  context 'with version history' do
    let(:c1) do
      PaperTrail.request(whodunnit: user.id) { super() }
    end
    let(:user2) do
      create(:user, first_name: 'someone', last_name: 'else').related_hmis_user(ds1)
    end

    before(:each) do
      # build a version history
      PaperTrail.request(whodunnit: user.id) { c1.update!(first_name: 'test1') }
      PaperTrail.request(whodunnit: user2.id) { c1.update!(first_name: 'test2') }
    end

    it 'should return the last users to create and update' do
      _response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'client', 'createdBy', 'id')).to eq user.id.to_s
      expect(result.dig('data', 'client', 'createdBy', 'name')).to eq [user.first_name, user.last_name].join(' ')
      expect(result.dig('data', 'client', 'user', 'id')).to eq user2.id.to_s
      expect(result.dig('data', 'client', 'user', 'name')).to eq [user2.first_name, user2.last_name].join(' ')
    end
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
      'addresses' => [{ 'line1' => '999 Test Ave' }],
      'phoneNumbers' => [{ 'value' => '5554567891', 'use' => 'home', 'system' => 'phone' }],
      'emailAddresses' => [{ 'value' => 'email@e.mail', 'use' => 'home', 'system' => 'email' }],
    )
    expect(result.dig('data', 'client', 'image')).not_to be_nil
  end

  context 'with a client who is chronically homeless per HUD definition' do
    let!(:c1) { create :hmis_hud_client_with_warehouse_client, data_source: ds1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, DisablingCondition: 1, MonthsHomelessThisTime: 13 }

    it 'should return chronic status correctly' do
      response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'client', 'hudChronic')).to eq(true)
    end
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
    remove_permissions(access_control, :can_view_clients)
    response, result = post_graphql(id: c1.id) { query }
    expect(response.status).to eq 200
    expect(result.dig('data', 'client')).to be_nil
  end

  it 'should return temp name if no custom client names' do
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client', 'names')).to contain_exactly(include('first' => c1.first_name, 'last' => c1.last_name))
  end

  it 'should return masked name if not allowed to see name' do
    remove_permissions(access_control, :can_view_client_name)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client', 'names')).to contain_exactly(include('first' => "Client #{c1.id}", 'last' => nil))
  end

  it 'should return no client photo if not allowed to see photos' do
    remove_permissions(access_control, :can_view_client_photo)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client', 'image')).to be_nil
  end

  it 'should return null DOB if not allowed to see DOB' do
    remove_permissions(access_control, :can_view_dob)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('dob' => nil, 'age' => c1.age)
  end

  it 'should return null SSN if not allowed to see SSN' do
    remove_permissions(access_control, :can_view_full_ssn, :can_view_partial_ssn)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('ssn' => nil)
  end

  it 'should return partial SSN if allowed to see partial but not full SSN' do
    remove_permissions(access_control, :can_view_full_ssn)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('ssn' => 'XXXXX6789')
  end

  it 'should return null address, email, and phone if not allowed to see contact info' do
    remove_permissions(access_control, :can_view_client_contact_info)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client', 'addresses')).to be_empty
    expect(result.dig('data', 'client', 'phoneNumbers')).to be_empty
    expect(result.dig('data', 'client', 'emailAddresses')).to be_empty
  end

  it 'should return no files if not allowed to see any' do
    remove_permissions(access_control, :can_manage_own_client_files, :can_view_any_confidential_client_files, :can_view_any_nonconfidential_client_files)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include('files' => { 'nodes' => be_empty })
  end

  it 'should return only non-confidential files if not allowed to see confidential' do
    remove_permissions(access_control, :can_manage_own_client_files, :can_view_any_confidential_client_files)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client')).to include(
      'files' => {
        'nodes' => contain_exactly(
          include('id' => f1.id.to_s),
          include(
            'id' => f2.id.to_s,
            'redacted' => true,
            'name' => 'Confidential File',
            'confidential' => true,
            'fileBlobId' => nil,
            'tags' => [],
            'updatedBy' => nil,
            'uploadedBy' => nil,
            'url' => nil,
          ),
        ),
      },
    )
  end

  it 'should return user\' own files if allowed to manage own files, regardless of any view permissions' do
    remove_permissions(access_control, :can_view_any_confidential_client_files, :can_view_any_nonconfidential_client_files)
    create :file, client: c1, blob: blob, user: nil, tags: [tag]
    expect(Hmis::File.count).to eq(3)
    _response, result = post_graphql(id: c1.id) { query }
    expect(result.dig('data', 'client', 'files', 'nodes')).to contain_exactly(include('id' => f1.id.to_s), include('id' => f2.id.to_s))
  end

  describe 'permissions base tests' do
    # Grant a few viewing permission to the whole data source
    let!(:ds_access_control) do
      create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details])
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

    it 'should have max permissions for an unenrolled client' do
      e1.destroy!
      _response, result = post_graphql(id: c1.id) { permissions_query }
      # Perms should match `access_control` which has all permissions enabled.
      check_client_access_with_role(result.dig('data', 'client', 'access'), access_control.role)
    end

    it 'should have permissions according to project where the client is enrolled' do
      _response, result = post_graphql(id: c1.id) { permissions_query }
      check_client_access_with_role(result.dig('data', 'client', 'access'), access_control.role)
    end

    it 'should only have data source permissions for a client enrolled at a project without user edit access' do
      e1.destroy!
      p2 = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1)
      create(:hmis_hud_enrollment, data_source: ds1, project: p2, client: c1, user: u1)
      _response, result = post_graphql(id: c1.id) { permissions_query }
      check_client_access_with_role(result.dig('data', 'client', 'access'), ds_access_control.role)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
