###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Graphql HMIS Assessment Eligibility', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query testQuery($enrollmentId: ID!) {
        enrollment(id: $enrollmentId) {
          id
          assessmentEligibilities {
            id
            title
            formDefinitionId
            role
            __typename
          }
          __typename
        }
      }
    GRAPHQL
  end
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  before(:each) do
    hmis_login(user)
  end

  def run_query(enrollment:)
    response, result = post_graphql(enrollmentId: enrollment.id) { query }
    expect(response.status).to eq(200)
    result.dig('data', 'enrollment', 'assessmentEligibilities').map { |n| n['role'] }
  end

  it 'resolves intake, exit, annual, and update' do
    records = run_query(enrollment: e1)
    expect(records).to contain_exactly('INTAKE', 'EXIT', 'ANNUAL', 'UPDATE')
  end

  context 'with custom assessment definitions' do
    # Active published form that also has retired and draft versions. Only the published one should be considered eligible.
    let!(:published_active_form) do
      fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published, version: 2)
      create(:hmis_form_instance, definition: fd, active: true, entity: e1.project)
      fd
    end
    let!(:retired_form) { create :hmis_form_definition, role: :CUSTOM_ASSESSMENT, identifier: published_active_form.identifier, status: :retired, version: 1 }
    let!(:draft_form) { create :hmis_form_definition, role: :CUSTOM_ASSESSMENT, identifier: published_active_form.identifier, status: :draft, version: 3 }

    # Ineligible because form instance is 'inactive'
    let!(:published_inactive_form) do
      fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published)
      create(:hmis_form_instance, definition: fd, active: false, entity: e1.project)
      fd
    end

    # Ineligible because form is only active in a different project
    let!(:published_inactive_form) do
      fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published)
      create(:hmis_form_instance, definition: fd, active: true, entity: create(:hmis_hud_project, data_source: ds1))
      fd
    end

    it 'only resolves published eligible custom assessment definition' do
      response, result = post_graphql(enrollmentId: e1.id) { query }
      expect(response.status).to eq(200)
      custom_assmt_eligibilities = result.dig('data', 'enrollment', 'assessmentEligibilities').filter { |n| n['role'] == 'CUSTOM_ASSESSMENT' }
      expect(custom_assmt_eligibilities).to contain_exactly(a_hash_including('formDefinitionId' => published_active_form.id.to_s))
    end
  end

  context 'with project entry' do
    before(:each) do
      create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, data_collection_stage: 1)
    end
    it 'resolves exit and annual and update' do
      records = run_query(enrollment: e1)
      expect(records).to contain_exactly('EXIT', 'ANNUAL', 'UPDATE')
    end

    context 'with project exit' do
      before(:each) do
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 3)
        create(:hmis_form_instance, entity: e1.project, definition_identifier: 'base-post_exit')
      end
      it 'resolves post-exit and annual' do
        records = run_query(enrollment: e1)
        expect(records).to contain_exactly('POST_EXIT')
      end
      context 'with project post-exit' do
        before(:each) do
          create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, data_collection_stage: 6)
        end
        it 'resolves nothing' do
          records = run_query(enrollment: e1)
          expect(records).to be_empty
        end
      end
    end
  end
end
