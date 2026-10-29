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
      query GetClientFiles(
        $id: ID!
        $limit: Int = 10
        $offset: Int = 0
        $includeOrganizationName: Boolean = false
      ) {
        client(id: $id) {
          id
          files(limit: $limit, offset: $offset) {
            offset
            limit
            nodesCount
            nodes {
              ...FileFields
              enrollment {
                ...ClientEnrollmentFields
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

      fragment ClientEnrollmentFields on Enrollment {
        id
        lockVersion
        entryDate
        exitDate
        autoExited
        moveInDate
        lastBedNightDate
        projectName
        organizationName @include(if: $includeOrganizationName)
        projectType
        inProgress
        relationshipToHoH
        access {
          id
          canViewEnrollmentDetails
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

  def resolved_file_ids(client)
    response, result = post_graphql(id: client.id, limit: 50) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'client', 'files', 'nodes').map { |node| node['id'].to_i }
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
  end

  describe 'n+1 queries' do
    # One access group for all projects. Permissions are loaded once per distinct set of access groups,
    # which is independent of how many files the client has.
    let!(:shared_access_control) { create_access_control(hmis_user, p1) }

    # Each enrollment file is at a different project and organization so that per-project policy
    # checks and organizationName are exercised, and each file has a different uploader.
    def create_files(count)
      count.times do
        project = create :hmis_hud_project, data_source: ds1, organization: create(:hmis_hud_organization, data_source: ds1)
        assign_viewable(shared_access_control, project)
        enrollment = create :hmis_hud_enrollment, data_source: ds1, project: project, client: c1
        uploader = create(:user).related_hmis_user(ds1)
        create :file, client: c1, enrollment: enrollment, blob: blob, user: uploader, updated_by: hmis_user, tags: [tag, tag2]
        create :file, client: c1, blob: blob, user: uploader, tags: [tag]
      end
    end

    def fetch_files(expected_count)
      count_database_queries do
        response, result = post_graphql(id: c1.id, limit: 100, include_organization_name: true) { query }
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

    it 'makes a reasonable number of queries' do
      create_files(15)
      expect do
        response, result = post_graphql(id: c1.id, limit: 100, include_organization_name: true) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'client', 'files', 'nodes').size).to eq(30)
      end.to make_database_queries(count: 15..40)
    end
  end
end
