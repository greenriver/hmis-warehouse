###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  include_context 'file upload setup'

  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:other_user) { create(:user).related_hmis_user(ds1) }
  let!(:access_control) do
    create_access_control(
      hmis_user,
      p1,
      with_permission: [
        :can_view_clients,
        :can_view_project,
        :can_view_enrollment_details,
        :can_view_any_nonconfidential_client_files,
        :can_view_any_confidential_client_files,
        :can_manage_any_client_files,
        :can_manage_own_client_files,
      ],
    )
  end

  before(:each) do
    hmis_login(user)
  end

  # Matches GetClientFiles in hmis-frontend (src/api/operations/client.queries.graphql), including its fragments
  let(:query) do
    <<~GRAPHQL
      query GetClientFiles($id: ID!, $limit: Int = 10, $offset: Int = 0) {
        client(id: $id) {
          id
          files(limit: $limit, offset: $offset) {
            offset
            limit
            nodesCount
            nodes {
              ...FileFields
              enrollment {
                id
                projectName
                organizationName
              }
            }
          }
        }
      }

      fragment FileFields on File {
        confidential
        contentType
        effectiveDate
        expirationDate
        id
        name
        note
        url
        tags
        access {
          canEditFile
          canDeleteFile
        }
        redacted
        enrollmentId
        enrollment {
          id
        }
        uploadedBy {
          id
          name
        }
        updatedBy {
          id
          name
        }
        dateCreated
        dateUpdated
        user {
          ...UserFields
        }
      }

      fragment UserFields on ApplicationUser {
        __typename
        id
        name
        firstName
        lastName
        email
      }
    GRAPHQL
  end

  def fetch_file_nodes(client)
    response, result = post_graphql(id: client.id, limit: 50) { query }
    expect(response.status).to eq(200), result.inspect
    expect(result['errors']).to be_nil
    result.dig('data', 'client', 'files', 'nodes')
  end

  def resolved_file_ids(client)
    fetch_file_nodes(client).map { |node| node['id'].to_i }
  end

  def file_node(client, file)
    fetch_file_nodes(client).find { |node| node['id'] == file.id.to_s }
  end

  describe 'client files' do
    let!(:p2) { create :hmis_hud_project, data_source: ds1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1 }
    let!(:client_file) { create :file, client: c1, blob: blob, user: other_user, tags: [tag] }
    let!(:enrollment_file) { create :file, client: c1, enrollment: e1, blob: blob, user: other_user, tags: [tag] }
    # User can view enrollments at p2 but has no file permissions there, so this is only visible because they uploaded it
    let!(:p2_access_control) do
      create_access_control(hmis_user, p2, with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details])
    end
    let!(:own_file_at_p2) { create :file, client: c1, enrollment: e2, blob: blob, user: hmis_user }
    let!(:other_file_at_p2) { create :file, client: c1, enrollment: e2, blob: blob, user: other_user }
    let!(:other_client_file) { create :file, client: create(:hmis_hud_client, data_source: ds1), blob: blob, user: hmis_user }

    it 'returns client-level, enrollment, and own files for the client only' do
      expect(resolved_file_ids(c1)).to contain_exactly(client_file.id, enrollment_file.id, own_file_at_p2.id)
    end

    it 'does not return own files without can_manage_own_client_files' do
      remove_permissions(access_control, :can_manage_own_client_files)
      expect(resolved_file_ids(c1)).to contain_exactly(client_file.id, enrollment_file.id)
    end

    it 'resolves file fields for an enrollment file' do
      enrollment_file.update!(updated_by: hmis_user)
      expect(file_node(c1, enrollment_file)).to include(
        'name' => enrollment_file.name,
        'contentType' => blob.content_type,
        'url' => hmis_client_file_path(client_id: c1.id, id: enrollment_file.id),
        'tags' => [tag.id.to_s],
        'redacted' => false,
        'enrollmentId' => e1.id.to_s,
        'enrollment' => { 'id' => e1.id.to_s, 'projectName' => p1.project_name, 'organizationName' => o1.organization_name },
        'uploadedBy' => { 'id' => other_user.id.to_s, 'name' => other_user.name },
        'updatedBy' => { 'id' => hmis_user.id.to_s, 'name' => hmis_user.name },
        'user' => include('id' => hmis_user.id.to_s),
        'access' => { 'canEditFile' => true, 'canDeleteFile' => true },
      )
    end

    it 'resolves file fields for a client-level file' do
      expect(file_node(c1, client_file)).to include(
        'url' => hmis_client_file_path(client_id: c1.id, id: client_file.id),
        'tags' => [tag.id.to_s],
        'enrollmentId' => nil,
        'enrollment' => nil,
        'uploadedBy' => { 'id' => other_user.id.to_s, 'name' => other_user.name },
        'updatedBy' => nil,
        'user' => include('id' => other_user.id.to_s),
      )
    end

    context 'with a confidential file the user cannot view' do
      let!(:confidential_file) { create :file, client: c1, blob: blob, user: other_user, tags: [tag], confidential: true, note: 'Secret note' }

      before { remove_permissions(access_control, :can_view_any_confidential_client_files) }

      it 'redacts the file contents' do
        expect(file_node(c1, confidential_file)).to include(
          'redacted' => true,
          'name' => 'Confidential File',
          'note' => nil,
          'url' => nil,
          'tags' => [],
          'uploadedBy' => nil,
          'updatedBy' => nil,
          'user' => nil,
          'access' => { 'canEditFile' => false, 'canDeleteFile' => false },
        )
      end
    end

    context 'with confidential files at projects with different confidential permissions' do
      let!(:confidential_file_at_p1) { create :file, client: c1, enrollment: e1, blob: blob, user: other_user, confidential: true, note: 'P1 note' }
      let!(:confidential_file_at_p2) { create :file, client: c1, enrollment: e2, blob: blob, user: other_user, confidential: true, note: 'P2 note' }

      # Confidential access at p1 only; p2 grants non-confidential file access so its files are listed but redacted
      before { add_permissions(p2_access_control, :can_view_any_nonconfidential_client_files) }

      it 'redacts each file based on its own project' do
        nodes = fetch_file_nodes(c1).index_by { |node| node['id'] }
        expect(nodes.fetch(confidential_file_at_p1.id.to_s)).to include('redacted' => false, 'note' => 'P1 note')
        expect(nodes.fetch(confidential_file_at_p2.id.to_s)).to include('redacted' => true, 'name' => 'Confidential File', 'note' => nil, 'url' => nil)
      end
    end

    context 'with an own file on an enrollment the user cannot view' do
      let!(:p3) { create :hmis_hud_project, data_source: ds1 }
      let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p3, client: c1 }
      let!(:own_file_at_p3) { create :file, client: c1, enrollment: e3, blob: blob, user: hmis_user }

      it 'returns the file with a null enrollment instead of failing the query' do
        expect(file_node(c1, own_file_at_p3)).to include('enrollmentId' => e3.id.to_s, 'enrollment' => nil)
      end
    end
  end

  describe 'n+1 queries' do
    # One access group for all projects. Permissions are loaded once per distinct set of access groups,
    # which is independent of how many files the client has.
    let!(:shared_access_control) { create_access_control(hmis_user, p1) }

    # Every file has its own project, organization, users, and tag. Per-file queries with identical
    # parameters are served by the query cache and not counted, so shared values would hide an N+1.
    def create_files(count)
      count.times do
        project = create :hmis_hud_project, data_source: ds1, organization: create(:hmis_hud_organization, data_source: ds1)
        assign_viewable(shared_access_control, project)
        enrollment = create :hmis_hud_enrollment, data_source: ds1, project: project, client: c1
        2.times do |i|
          create(
            :file,
            client: c1,
            enrollment: i.zero? ? enrollment : nil,
            blob: blob,
            user: create(:user).related_hmis_user(ds1),
            updated_by: create(:user).related_hmis_user(ds1),
            tags: [GrdaWarehouse::AvailableFileTag.create!(name: "Tag #{SecureRandom.hex(4)}")],
          )
        end
      end
    end

    def fetch_files(expected_count)
      count_database_queries do
        response, result = post_graphql(id: c1.id, limit: 100) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'client', 'files', 'nodes').size).to eq(expected_count)
      end
    end

    it 'does not grow with the number of files' do
      create_files(5)
      fetch_files(10) # warm up per-process caches so they don't count toward the first measurement
      queries_for_10_files = fetch_files(10)

      create_files(10)
      queries_for_30_files = fetch_files(30)

      expect(queries_for_30_files).to eq(queries_for_10_files)
    end

    it 'stays under 37 queries for 30 files' do
      create_files(15)
      expect do
        response, result = post_graphql(id: c1.id, limit: 100) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'client', 'files', 'nodes').size).to eq(30)
      end.to make_database_queries(count: 15..37)
    end
  end
end
