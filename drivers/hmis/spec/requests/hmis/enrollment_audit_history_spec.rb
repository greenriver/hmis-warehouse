###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Client Audit History Query', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query TestQuery($id: ID!, $filters: EnrollmentAuditEventFilterOptions!) {
        enrollment(id: $id) {
          id
          auditHistory(limit: 10, offset: 0, filters: $filters) {
            nodes {
              id
              createdAt
              event
              objectChanges
              recordName
              recordId
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
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details, :can_audit_enrollments])
  end
  let(:today) { Date.current }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: today - 2.days }

  before(:each) { hmis_login(user) }

  def run_query(id:, filters:)
    response, result = post_graphql(id: id, filters: filters) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'enrollment', 'auditHistory', 'nodes')
  end

  context 'enrollment updated by several users' do
    let!(:user2) { create(:user) }
    let!(:hmis_user2) { user2.related_hmis_user(ds1) }

    before(:each) do
      PaperTrail.request(controller_info: { user_id: hmis_user.id }) do
        e1.update!(entry_date: today - 1.day)
      end
      PaperTrail.request(controller_info: { user_id: hmis_user2.id }) do
        e1.update!(entry_date: today)
      end
    end
    it 'filters users' do
      records = run_query(id: e1.id, filters: { user: [hmis_user2.id.to_s] })
      expect(records.size).to eq(1)
      expect(records.dig(0, 'objectChanges', 'entryDate', 'values')).
        to eq([today - 1.day, today].map { |d| d.to_s(:db) })
    end
  end

  context 'enrollment with entry and exit date change' do
    before(:each) do
      e1.update!(entry_date: today - 1.day)
      create(:hmis_hud_exit, personal_id: c1.personal_id, enrollment: e1, data_source: ds1, exit_date: today)
    end
    it 'filters by exit record type' do
      records = run_query(id: e1.id, filters: { enrollment_record_type: ['Hmis::Hud::Exit'] })
      expect(records.size).to eq(1)
      expect(records.dig(0, 'recordName')).to eq('Exit')
    end
  end

  context 'enrollment with custom assessment' do
    let(:form_definition) { create(:hmis_form_definition) }
    let!(:custom_assessment) do
      create(:hmis_custom_assessment, definition: form_definition, enrollment: e1, client: e1.client, data_source: ds1, data_collection_stage: 99)
    end
    shared_examples 'assesses correct title' do
      it 'shows the correct assessment title' do
        records = run_query(id: e1.id, filters: { enrollment_record_type: ['Hmis::Hud::CustomAssessment'] })
        expect(records.dig(0, 'recordName')).to eq(form_definition.title)
      end
    end

    include_examples 'assesses correct title'

    context 'deleted' do
      before(:each) { custom_assessment.destroy! }
      include_examples 'assesses correct title'
    end
  end
end
