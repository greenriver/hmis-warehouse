###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Client Audit History Query', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query GetClient($id: ID!, $filters: ClientAuditEventFilterOptions) {
        client(id: $id) {
          id
          auditHistory(limit: 10, offset: 0, filters: $filters) {
            nodes {
              id
              createdAt
              event
              objectChanges
              recordName
              recordId
              graphqlType
              user {
                id
                name
              }
            }
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_audit_clients, :can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details])
  end
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  before(:each) { hmis_login(user) }

  def run_query(id:, filters: nil)
    response, result = post_graphql(id: id, filters: filters) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'client', 'auditHistory', 'nodes')
  end

  context 'client updated by several users' do
    let!(:user2) { create(:user) }
    let!(:hmis_user2) { user2.related_hmis_user(ds1) }
    let!(:c1) { create :hmis_hud_client, data_source: ds1, Man: 1 }

    before(:each) do
      PaperTrail.request(controller_info: { user_id: hmis_user.id }) do
        c1.update!(Man: 0)
      end
      PaperTrail.request(controller_info: { user_id: hmis_user2.id }) do
        c1.update!(Man: 1)
      end
    end
    it 'filters users' do
      records = run_query(id: c1.id, filters: { user: [hmis_user2.id.to_s] })
      expect(records.size).to eq(1)
      expect(records.dig(0, 'objectChanges', 'gender', 'values')).to eq([nil, ['MAN']])
    end
  end

  context 'client with demographics and address change' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, Man: 1 }
    before(:each) do
      c1.update!(Man: 0)
      create(:hmis_hud_custom_client_address, client: c1, data_source: ds1)
    end
    it 'filters by address record type' do
      records = run_query(id: c1.id, filters: { client_record_type: ['Hmis::Hud::CustomClientAddress'] })
      expect(records.size).to eq(1)
      expect(records.dig(0, 'recordName')).to eq('Address')
    end
  end

  context 'client record with two genders' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, Man: 1, CulturallySpecific: 1 }
    context 'changing to one gender' do
      before(:each) { c1.update!(Man: 0) }
      it 'reports change' do
        records = run_query(id: c1.id)
        expect(records.size).to eq(2)
        expect(records.dig(0, 'objectChanges', 'gender', 'values')).to eq([['MAN', 'CULTURALLY_SPECIFIC'], ['CULTURALLY_SPECIFIC']])
        expect(records.dig(1, 'objectChanges', 'gender', 'values')).to eq([nil, ['MAN', 'CULTURALLY_SPECIFIC']])
      end
    end
  end

  context 'client record with no race' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, RaceNone: nil, HispanicLatinaeo: nil }
    context 'changing to one race' do
      before(:each) { c1.update!(HispanicLatinaeo: 1) }
      it 'reports change' do
        records = run_query(id: c1.id)
        expect(records.size).to eq(2)
        expect(records.dig(0, 'objectChanges', 'race', 'values')).to eq([nil, ['HISPANIC_LATINAEO']])
        expect(records.dig(1, 'objectChanges', 'race', 'values')).to be_nil
      end
    end
  end

  # Restriction versions have no meaningful column changes of their own, so they are presented as
  # an update to the restrictable's `restricted` field.
  # See docs/features/hmis/hmis-restricted-records.md#audit-trail.
  describe 'record restriction events' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1 }

    # Creating the client writes a Client `create` version of its own, so these scope to the
    # restriction record type rather than counting every row the setup produces.
    def restriction_records(id)
      run_query(id: id, filters: { client_record_type: ['Hmis::RestrictedRecord'] })
    end

    def restriction_values(records)
      records.map { |record| record.dig('objectChanges', 'restricted', 'values') }
    end

    it 'reports restricting a client' do
      c1.mark_as_restricted!(user: hmis_user)

      records = restriction_records(c1.id)
      expect(records.size).to eq(1)
      expect(records.dig(0, 'recordName')).to eq('Record Restriction')
      expect(records.dig(0, 'event')).to eq('update')
      expect(restriction_values(records)).to eq([[false, true]])
    end

    # The synthesized `restricted` change only renders as Yes/No because the frontend resolves it
    # against Client in the generated schema. Reporting any other type silently degrades it to a
    # raw `true`/`false`, which no other assertion here would catch.
    it 'reports the restrictable type, so the change resolves against a real schema field' do
      c1.mark_as_restricted!(user: hmis_user)
      c1.reload.remove_restriction!

      records = restriction_records(c1.id)
      expect(records.size).to eq(2)
      expect(records.map { |record| record['graphqlType'] }.uniq).to eq(['Client'])
      expect(records.map { |record| record.dig('objectChanges', 'restricted', 'fieldName') }.uniq).to eq(['restricted'])
    end

    it 'includes the restriction alongside the other audit events for the client' do
      c1.mark_as_restricted!(user: hmis_user)

      expect(run_query(id: c1.id).map { |r| r['recordName'] }).to include('Record Restriction')
    end

    it 'reports removing a restriction' do
      c1.mark_as_restricted!(user: hmis_user)
      c1.reload.remove_restriction!

      records = restriction_records(c1.id)
      expect(records.size).to eq(2)
      expect(restriction_values(records)).to contain_exactly([false, true], [true, false])
    end

    it 'reports each restriction when a client is restricted again' do
      c1.mark_as_restricted!(user: hmis_user)
      c1.reload.remove_restriction!
      c1.reload.mark_as_restricted!(user: hmis_user)

      records = restriction_records(c1.id)
      expect(records.size).to eq(3)
      expect(restriction_values(records)).to contain_exactly([false, true], [false, true], [true, false])
    end

    # Reproduces the shape the old mark! left behind on a second restriction: Paranoia's restore
    # skipped PaperTrail, so the created_by re-stamp that followed it wrote the only version, and
    # only when a different user acted. Nothing writes versions like this anymore, but they are
    # still in the table. See docs/features/hmis/hmis-restricted-records.md#audit-trail.
    it 'reads a legacy update version as a restriction' do
      c1.mark_as_restricted!(user: hmis_user)
      c1.reload.remove_restriction!

      revived = Hmis::RestrictedRecord.with_deleted.find_by(restrictable: c1)
      revived.update_columns(deleted_at: nil)
      revived.update!(created_by: create(:user).related_hmis_user(ds1))

      records = restriction_records(c1.id)
      expect(records.size).to eq(3)
      expect(restriction_values(records)).to contain_exactly([false, true], [true, false], [false, true])
      expect(records.map { |record| record['graphqlType'] }.uniq).to eq(['Client'])
    end

    it 'attributes the restriction to the acting user' do
      PaperTrail.request(whodunnit: hmis_user.id.to_s) do
        c1.mark_as_restricted!(user: hmis_user)
      end

      expect(restriction_records(c1.id).dig(0, 'user', 'id')).to eq(hmis_user.id.to_s)
    end

    it 'can be filtered out by record type' do
      c1.mark_as_restricted!(user: hmis_user)
      c1.update!(Man: 1)

      records = run_query(id: c1.id, filters: { client_record_type: ['Hmis::Hud::Client'] })
      expect(records).to be_present
      expect(records.map { |r| r['recordName'] }.uniq).to eq(['Client'])
    end

    it 'can be filtered down to by record type, using the code the picklist offers' do
      c1.mark_as_restricted!(user: hmis_user)
      c1.update!(Man: 1)

      option = Types::Forms::PickListOption.client_audit_event_record_type_picklist.
        find { |o| o[:label] == 'Record Restriction' }
      expect(option).to be_present

      records = run_query(id: c1.id, filters: { client_record_type: [option[:code]] })
      expect(records.size).to eq(1)
      expect(records.dig(0, 'recordName')).to eq('Record Restriction')
    end
  end

  describe 'authorization' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, Man: 1 }
    before(:each) { c1.update!(Man: 0) }

    it 'denies access when the user cannot audit clients, even though they can view the client' do
      remove_permissions(access_control, :can_audit_clients)
      expect_access_denied post_graphql(id: c1.id, filters: nil) { query }
    end

    it 'resolves audit history when the user can audit clients' do
      expect(run_query(id: c1.id)).to be_present
    end
  end

  # can_audit_clients is documented as granting visibility into DOB, SSN, and name changes even when
  # the user lacks the field-level permissions for those attributes on the Client (see Hmis::Role).
  describe 'PII in objectChanges' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1, SSN: '123456789', DOB: '1980-01-01' }
    before(:each) { c1.update!(SSN: '987654321', DOB: '1990-02-02') }

    it 'reports SSN and DOB changes without the field-level client permissions' do
      remove_permissions(access_control, :can_view_dob)

      keys = run_query(id: c1.id).flat_map { |record| record['objectChanges']&.keys || [] }
      expect(keys).to include('ssn', 'dob')
    end
  end
end
