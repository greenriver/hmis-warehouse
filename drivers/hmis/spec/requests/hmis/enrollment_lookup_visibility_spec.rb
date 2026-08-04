###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

# Visibility for the top-level enrollment(id:) lookup.
# Note: enrollment(id:) requires full enrollment details access (can_view_details?).
# Limited enrollment access alone is not enough to resolve this query — that permission
# is for nested enrollments on the client dashboard (see client_enrollments_visibility_spec).
#
# Lookup uses Enrollment.viewable_by → Project.with_enrollment_details_viewable_by, which resolves
# can_view_enrollment_details through UserContext, so its requirements (can_view_project and
# can_view_clients) are enforced the same way the policies enforce them: unioned across the user's
# roles at the project.
RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, sexual_orientation: 1 }
  let!(:cls) { create :hmis_current_living_situation, data_source: ds1, client: c1, enrollment: e1 }

  # Canary: enrollment / CLS at another project should never leak through this lookup
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1 }
  let!(:cls2) { create :hmis_current_living_situation, data_source: ds1, client: c1, enrollment: e2 }

  before(:each) { hmis_login(user) }

  let(:query) do
    <<~GRAPHQL
      query Enrollment($id: ID!) {
        enrollment(id: $id) {
          id
          entryDate
          projectName
          status
          sexualOrientation
          access {
            canViewEnrollmentDetails
          }
          currentLivingSituations {
            nodesCount
            nodes {
              id
            }
          }
          client {
            id
          }
        }
      }
    GRAPHQL
  end

  def fetch_enrollment(enrollment = e1)
    response, result = post_graphql(id: enrollment.id.to_s) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'enrollment')
  end

  describe 'with full enrollment details access' do
    let!(:access_control) do
      create_access_control(
        hmis_user,
        p1,
        with_permission: HmisPermissionSets::ENROLLMENT_VISIBILITY,
      )
    end

    it 'resolves the enrollment with detail fields and related records' do
      enrollment = fetch_enrollment
      expect(enrollment).to include(
        'id' => e1.id.to_s,
        'status' => 'ACTIVE',
        'entryDate' => e1.entry_date.strftime('%Y-%m-%d'),
        'projectName' => p1.project_name,
        'sexualOrientation' => 'HETEROSEXUAL',
      )
      expect(enrollment.dig('access', 'canViewEnrollmentDetails')).to eq(true)
      expect(enrollment.dig('client', 'id')).to eq(c1.id.to_s)
      # CLS from e2 must not appear even though it shares the same client
      expect(enrollment.dig('currentLivingSituations', 'nodesCount')).to eq(1)
      expect(enrollment.dig('currentLivingSituations', 'nodes').map { |n| n['id'] }).to contain_exactly(cls.id.to_s)
    end

    it 'does not resolve enrollments at projects without access' do
      expect(fetch_enrollment(e2)).to be_nil
    end
  end

  describe 'without can_view_enrollment_details' do
    let!(:access_control) do
      create_access_control(
        hmis_user,
        p1,
        with_permission: [:can_view_project, :can_view_clients],
      )
    end

    it 'returns null' do
      expect(Hmis::Hud::Enrollment.viewable_by(hmis_user)).not_to include(e1)
      expect(fetch_enrollment).to be_nil
    end
  end

  describe 'without can_view_project' do
    let!(:access_control) do
      create_access_control(
        hmis_user,
        p1,
        with_permission: [:can_view_enrollment_details, :can_view_clients],
      )
    end

    it 'returns null' do
      expect(Hmis::Hud::Enrollment.viewable_by(hmis_user)).not_to include(e1)
      expect(fetch_enrollment).to be_nil
    end
  end

  describe 'without can_view_clients' do
    let!(:access_control) do
      create_access_control(
        hmis_user,
        p1,
        with_permission: [:can_view_project, :can_view_enrollment_details],
      )
    end

    it 'returns null even when enrollment-detail permissions are present' do
      expect(Hmis::Hud::Client.viewable_by(hmis_user)).not_to include(c1)
      expect(Hmis::Hud::Enrollment.viewable_by(hmis_user)).not_to include(e1)
      expect(fetch_enrollment).to be_nil
    end
  end

  # The scope resolves permissions the way the policies do, so a requirement satisfied by a second
  # role at the same project counts. Splitting the same permissions across projects does not (below).
  describe 'with the required permissions split across two roles at the same project' do
    let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_enrollment_details]) }
    let!(:other_access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_view_clients]) }

    it 'resolves the enrollment' do
      expect(Hmis::Hud::Enrollment.viewable_by(hmis_user)).to include(e1)
      expect(fetch_enrollment).to include('id' => e1.id.to_s)
    end
  end

  describe 'with the required permissions split across projects' do
    let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_enrollment_details]) }
    let!(:other_access_control) { create_access_control(hmis_user, p2, with_permission: [:can_view_project, :can_view_clients]) }

    it 'returns null' do
      expect(Hmis::Hud::Enrollment.viewable_by(hmis_user)).not_to include(e1)
      expect(fetch_enrollment).to be_nil
    end
  end

  describe 'with only limited enrollment access' do
    let!(:access_control) do
      create_access_control(
        hmis_user,
        p1,
        with_permission: HmisPermissionSets::LIMITED_ENROLLMENT_VISIBILITY,
      )
    end

    it 'returns null (top-level lookup requires full details access)' do
      expect(fetch_enrollment).to be_nil
    end
  end

  describe 'with no permissions' do
    it 'returns null' do
      expect(fetch_enrollment).to be_nil
    end
  end

  describe 'with permissions only on a different project' do
    let!(:access_control) do
      create_access_control(
        hmis_user,
        p2,
        with_permission: HmisPermissionSets::ENROLLMENT_VISIBILITY,
      )
    end

    it 'returns null for enrollments at inaccessible projects' do
      expect(fetch_enrollment(e1)).to be_nil
    end

    it 'resolves enrollments at the assigned project' do
      enrollment = fetch_enrollment(e2)
      expect(enrollment).to include('id' => e2.id.to_s)
      expect(enrollment.dig('currentLivingSituations', 'nodes').map { |n| n['id'] }).to contain_exactly(cls2.id.to_s)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
