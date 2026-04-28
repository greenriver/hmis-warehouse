# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Per-field comprehensive coverage for `client { access { ... } }`,
# testing each access field based on the raw permissions the user must have.
# Does not test permission logic based on project/data source perms or enrolled/unenrolled clients;
# See lookup_client_spec.rb and client_access_spec.rb
require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) { hmis_login(user) }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  def fetch_client_access_field(graphql_field_name)
    response, result = post_graphql(id: c1.id) do
      <<~GRAPHQL
        query ClientAccess($id: ID!) {
          client(id: $id) {
            access {
              #{graphql_field_name}
            }
          }
        }
      GRAPHQL
    end
    expect(response.status).to eq(200), result.inspect
    access_object = result.dig('data', 'client', 'access') || (raise "no access: #{result.inspect}")
    access_object[graphql_field_name]
  end

  # Each [access_field_name, permission_name] pair maps a GraphQL field to the HMIS role permission(s)
  # that must be present for that field to resolve true.
  CLIENT_ACCESS_FIELD_PERMISSIONS = [
    ['canViewClientName', 'can_view_client_name'],
    ['canMergeClients', 'can_merge_clients'],
    ['canViewReferrals', 'can_view_referrals'],
    ['canViewOwnReferrals', 'can_view_own_referrals'],
    ['canViewPartialSsn', 'can_view_partial_ssn'],
    ['canViewFullSsn', 'can_view_full_ssn'],
    ['canViewClientPhoto', 'can_view_client_photo'],
    ['canViewDob', 'can_view_dob'],
    ['canViewEnrollmentDetails', 'can_view_enrollment_details'],
    ['canDeleteClient', 'can_delete_clients'],
    ['canEditClient', 'can_edit_clients'],
    ['canManageAnyClientFiles', 'can_manage_any_client_files'],
    ['canManageOwnClientFiles', 'can_manage_own_client_files'],
    ['canAuditClients', 'can_audit_clients'],
    ['canManageScanCards', 'can_manage_scan_cards'],
    ['canViewClientAlerts', 'can_view_client_alerts'],
    ['canManageClientAlerts', 'can_manage_client_alerts'],
    ['canPrintClientCaseNotes', 'can_print_client_case_notes'],
    ['canViewClientEligibleOpportunities', 'can_view_client_eligible_opportunities'],
    ['canUploadClientFiles', ['can_manage_any_client_files', 'can_manage_own_client_files']],
    ['canViewAnyFiles', ['can_manage_own_client_files', 'can_view_any_nonconfidential_client_files', 'can_view_any_confidential_client_files']],
  ].freeze

  describe 'client { access }' do
    CLIENT_ACCESS_FIELD_PERMISSIONS.each do |graphql_field, permissions|
      it "resolves #{graphql_field} only when the user has permission" do
        expect(fetch_client_access_field(graphql_field)).to be true

        if permissions.is_a?(Array)
          remove_permissions(access_control, *permissions)
        else
          remove_permissions(access_control, permissions)
        end
        expect(fetch_client_access_field(graphql_field)).to be false
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
