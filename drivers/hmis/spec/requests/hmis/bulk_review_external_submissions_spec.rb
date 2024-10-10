###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Bulk Review External Submission', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation BulkReviewExternalSubmissions(
        $ids: [ID!]!
      ) {
        bulkReviewExternalSubmissions(externalSubmissionIds: $ids) {
          success
        }
      }
    GRAPHQL
  end

  let!(:access_control) do
    create_access_control(hmis_user, p1, with_permission: [:can_manage_external_form_submissions, :can_view_project, :can_edit_enrollments])
  end

  before(:each) do
    hmis_login(user)
  end

  let!(:definition) { create(:hmis_external_form_definition) }
  let!(:rule) { create :hmis_form_instance, definition_identifier: definition.identifier, entity: p1, active: true }
  let!(:s1) { create(:hmis_external_form_submission, definition: definition, raw_data: { 'your_name' => 'Abigail' }) }
  let!(:s2) { create(:hmis_external_form_submission, definition: definition, raw_data: { 'your_name' => 'Cedric' }) }
  let!(:cded) { create(:hmis_custom_data_element_definition, owner_type: s1.class.sti_name, key: 'your_name', data_source: ds1, user: u1) }

  def perform_mutation(ids: [s1.id, s2.id])
    post_graphql(ids: ids) { mutation }
  end

  it 'successfully bulk-reviews submissions' do
    expect do
      perform_mutation
      s1.reload
      s2.reload
    end.to change(s1, :status).from('new').to('reviewed').
      and change(s1, :updated_at).
      and change(s2, :status).from('new').to('reviewed').
      and change(s2, :updated_at).
      and change(Hmis::Hud::CustomDataElement, :count).by(2).
      and not_change(Hmis::Hud::Enrollment, :count)
  end

  it 'throws an error on already-reviewed submissions' do
    s1.status = 'reviewed'
    s1.save!
    expect_gql_error perform_mutation
  end

  it 'throws an error when submissions are from different forms' do
    other_definition = create(:hmis_external_form_definition)
    other_submission = create(:hmis_external_form_submission, definition: other_definition)
    expect_gql_error perform_mutation(ids: [s1.id, s2.id, other_submission.id])
  end

  context 'when some submissions fail but others are fine' do
    let!(:s3) { create(:hmis_external_form_submission, status: 'reviewed', definition: definition, raw_data: { 'your_name' => 'Barry' }) }
    let!(:s4) { create(:hmis_external_form_submission, definition: definition, raw_data: { 'some_invalid_key' => 'Bad data!' }) }

    it 'succeeds with the non-problematic submissions' do
      expect do
        expect_gql_error perform_mutation(ids: [s1.id, s2.id, s3.id, s4.id]), message: /Bulk review failed on 2 of 4 records./
        s1.reload
        s2.reload
        s3.reload
        s4.reload
      end.to change(s1, :status).from('new').to('reviewed').
        and change(s2, :status).from('new').to('reviewed').
        and not_change(s3, :status).
        and not_change(s4, :status)
    end
  end

  context 'when the user does not have permission on the right project' do
    let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }
    let!(:ac2) do
      remove_permissions(access_control, :can_manage_external_form_submissions)
      create_access_control(hmis_user, p2, with_permission: [:can_manage_external_form_submissions, :can_view_project, :can_edit_enrollments])
    end

    it 'throws an error and does not process' do
      expect do
        response, result = perform_mutation
        expect(response.status).to eq(500), result.inspect
        expect(result.dig('errors', 0, 'message')).to eq('access denied')
        s1.reload
        s2.reload
      end.to not_change(s1, :status).
        and not_change(s2, :status).
        and not_change(Hmis::Hud::CustomDataElement, :count)
    end
  end

  context 'when the form updates client and enrollment info' do
    let!(:definition) { create(:hmis_external_form_definition_updates_client) }

    let!(:s1) do
      create(:hmis_external_form_submission, raw_data: { 'Client.firstName': 'Oranges' }.stringify_keys, definition: definition)
    end

    let!(:s2) do
      create(:hmis_external_form_submission, raw_data: { 'Client.firstName': 'Apples' }.stringify_keys, definition: definition)
    end

    it 'processes both submissions, creating 2 new clients and enrollments' do
      expect do
        perform_mutation
      end.to change(Hmis::Hud::Client, :count).by(2).
        and change(Hmis::Hud::Enrollment, :count).by(2)

      s1.reload
      expect(s1.enrollment.client.first_name).to eq('Oranges')

      s2.reload
      expect(s2.enrollment.client.first_name).to eq('Apples')
    end

    context 'when a submission in the list already has an enrollment' do
      let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Apples' }
      let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
      let!(:s3) { create(:hmis_external_form_submission, definition: definition, status: 'reviewed', enrollment: e1) }

      it 'throws an error and does not process' do
        expect do
          response, result = perform_mutation(ids: [s3.id])
          expect(response.status).to eq(500), result.inspect
          s3.reload
        end.to not_change(s3, :status).
          and not_change(Hmis::Hud::Client, :count).
          and not_change(Hmis::Hud::Enrollment, :count)
      end
    end
  end
end
