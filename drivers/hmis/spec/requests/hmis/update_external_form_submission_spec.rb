###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Update External Form Submission', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation UpdateExternalFormSubmission(
        $id: ID!
        $input: ExternalFormSubmissionInput!
      ) {
        updateExternalFormSubmission(id: $id, input: $input) {
          externalFormSubmission {
            id
            submittedAt
            spam
            status
            notes
            definition {
              identifier
            }
            values
          }
          #{error_fields}
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
  let!(:instance) { create(:hmis_form_instance, definition: definition, entity: p1) }
  let!(:submission) { create(:hmis_external_form_submission, definition: definition) }
  let!(:cded) { create(:hmis_custom_data_element_definition, owner_type: submission.class.sti_name, key: 'your_name', data_source: ds1, user: u1) }
  let!(:input) do
    {
      id: submission.id,
      input: {
        status: 'reviewed',
      },
    }
  end
  let(:today) { Date.current }

  context 'when user lacks can_manage_external_form_submissions' do
    before(:each) { remove_permissions(access_control, :can_manage_external_form_submissions) }

    it 'access is denied' do
      expect_access_denied post_graphql(input) { mutation }
    end

    it 'access is denied (user has perm in a different project)' do
      p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
      create_access_control(hmis_user, p2, with_permission: [:can_manage_external_form_submissions, :can_view_project])

      expect_access_denied post_graphql(input) { mutation }
    end
  end

  context 'when submission was already reviewed' do
    let!(:submission) { create(:hmis_external_form_submission, definition: definition, status: 'reviewed') }

    it 'cannot update back to new' do
      response, result = post_graphql({ **input, input: { status: 'new' } }) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'updateExternalFormSubmission', 'errors', 0, 'fullMessage')).to eq('Cannot change status from Reviewed to New')
    end
  end

  context 'when reviewing a submission' do
    it 'should create CDE' do
      expect do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
      end.to change(Hmis::Hud::CustomDataElement, :count).by(1).
        and not_change(Hmis::Hud::Enrollment, :count).
        and not_change(Hmis::Hud::Client, :count)
    end

    context 'when there is an unexpected key on the input' do
      let!(:submission) do
        data = {
          'foo': 'bar',
        }.stringify_keys
        create(:hmis_external_form_submission, raw_data: data, definition: definition)
      end

      it 'should raise an error' do
        expect do
          expect_gql_error(post_graphql(input) { mutation })
        end.to not_change(Hmis::Hud::CustomDataElement, :count)
      end
    end

    context 'when the form definition accepts client/enrollment information' do
      let!(:definition) { create(:hmis_external_form_definition_updates_client) }
      let!(:input) do
        {
          id: submission.id,
          input: {
            status: 'reviewed',
          },
        }
      end

      context 'when the submission specifies client info only' do
        let!(:submission) do
          data = {
            'Client.firstName': 'Oranges',
            'captcha_score': '1.', # also test that extraneous fields get filtered out
            'form_definition_id': definition.id,
            'form_content_digest': 'something random',
            'Geolocation.coordinates': '',
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should create both client and enrollment' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1).
            and not_change(ClientLocationHistory::Location, :count)

          submission.reload
          expect(submission.enrollment.relationship_to_hoh).to eq(1)
        end
      end

      context 'when the submission specifies a valid household ID and relationship to HoH' do
        let!(:household_id) { 'HH_' + Hmis::Hud::Enrollment.generate_household_id.truncate(20, omission: '') }
        let!(:submission) do
          data = {
            'Client.firstName': 'Oranges',
            'Enrollment.householdId': household_id,
            'Enrollment.relationshipToHoH': 'SPOUSE_OR_PARTNER',
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should create enrollment with correct household ID and relationship to HoH' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1)

          submission.reload
          expect(submission.enrollment.household_id).to eq(household_id)
          expect(submission.enrollment.relationship_to_hoh).to eq(3)
        end
      end

      context 'when the submission specifies an invalid relationship to HoH' do
        let!(:submission) do
          data = {
            'Client.firstName': 'Oranges',
            'Enrollment.relationshipToHoH': 'foo bar',
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should create enrollment defaulting to SELF relationship to HoH' do
          response, result = post_graphql(input) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')

          submission.reload
          expect(submission.enrollment.relationship_to_hoh).to eq(1)
        end
      end

      context 'when the submission specifies an existing household ID' do
        let!(:household_id) { 'HH_' + Hmis::Hud::Enrollment.generate_household_id.truncate(20, omission: '') }
        let!(:existing_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, household_id: household_id }
        let!(:submission) do
          data = {
            'Client.firstName': 'Oranges',
            'Enrollment.householdId': existing_enrollment.household_id,
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should create enrollment with same household ID and default to Data Not Collected for relationship to HoH' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1)

          submission.reload
          expect(submission.enrollment.household.enrollments).to include(existing_enrollment)
          expect(submission.enrollment.relationship_to_hoh).to eq(99)
        end
      end

      context 'when the submission specifies an invalid household ID that already exists in another project' do
        let!(:p2) { create :hmis_hud_project, data_source: ds1 }
        let!(:existing_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p2 }
        let!(:submission) do
          data = {
            'Client.firstName': 'Oranges',
            'Enrollment.householdId': existing_enrollment.household_id,
            'Enrollment.relationshipToHoH': 'SPOUSE_OR_PARTNER',
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should create enrollment in a new HH' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1)

          submission.reload
          expect(submission.enrollment.household_id).not_to eq(existing_enrollment.household_id)
          expect(submission.enrollment.household.enrollments.count).to eq(1)
          expect(submission.enrollment.relationship_to_hoh).to eq(1) # provided relationship to HoH is also overridden
        end
      end

      context 'when the submission specifies a household ID that is brand new' do
        let!(:submission) do
          data = {
            'Client.firstName': 'Oranges',
            'Enrollment.householdId': Hmis::Hud::Enrollment.generate_household_id,
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should create enrollment in a new HH' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1)

          submission.reload
          expect(submission.enrollment.household.enrollments.count).to eq(1)
          expect(submission.enrollment.relationship_to_hoh).to eq(1)
        end
      end

      context 'when the submission specifies a client attribute that is invalid' do
        let!(:submission) do
          data = {
            'Client.firstName': 'bar',
            'Client.veteranStatus': 'foo',
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should raise an error and not process the client' do
          expect do
            expect_gql_error(post_graphql(input) { mutation })
          end.to not_change(Hmis::Hud::CustomDataElement, :count).
            and not_change(Hmis::Hud::Client, :count)
        end
      end

      context 'when the submission specifies a client attribute that is blank' do
        let!(:submission) do
          data = {
            'Client.firstName': 'bar',
            'Client.veteranStatus': '',
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should process the blank attribute as data not collected' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1).
            and not_change(ClientLocationHistory::Location, :count)

          submission.reload
          expect(submission.enrollment.client.veteran_status).to eq(99)
        end
      end

      context 'when the submission specifies age range, a special-case client attribute' do
        let!(:submission) do
          data = {
            'Client.firstName': 'foobar',
            'Client.ageRange': '18-24',
            'Client.dob': '',
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should process the age range onto DOB with low data quality' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1)

          submission.reload
          expect(submission.enrollment.client.dob).to be_between(today - 24.years, today - 18.years)
          expect(submission.enrollment.client.dob_data_quality).to eq(2)
        end
      end

      context 'when age range is filled out as unknown' do
        let!(:submission) do
          data = {
            'Client.firstName': 'foobar',
            'Client.ageRange': "Doesn't know / Prefers not to answer",
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should process onto data quality 99' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1)

          submission.reload
          expect(submission.enrollment.client.dob).to be_nil
          expect(submission.enrollment.client.dob_data_quality).to eq(99)
        end
      end

      context 'when the submission specifies age range with an open-ended range' do
        let!(:submission) do
          data = {
            'Client.firstName': 'foobar',
            'Client.ageRange': '65+',
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should process the age range' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1)

          submission.reload
          expect(submission.enrollment.client.dob).to be_between(today - 90.years, today - 65.years)
          expect(submission.enrollment.client.dob_data_quality).to eq(2)
        end
      end

      context 'when submission specifies both age group and exact DOB' do
        let!(:submission) do
          data = {
            'Client.firstName': 'foobar',
            'Client.ageRange': '18-24',
            'Client.dob': (today - 20.years).to_formatted_s(:iso8601),
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should prioritize exact DOB' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1)

          submission.reload
          expect(submission.enrollment.client.dob).to eq(today - 20.years)
          expect(submission.enrollment.client.dob_data_quality).to be_nil
        end
      end

      context 'when the submission specifies geolocation' do
        let!(:submission) do
          data = {
            'Client.firstName': 'bar',
            'Geolocation.coordinates': { 'latitude': 40.812497, 'longitude': -77.882926 }.to_json,
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition, submitted_at: 1.day.ago)
        end

        it 'should save to Client Location History table' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1).
            and change(ClientLocationHistory::Location, :count).by(1)

          submission.reload
          expect(submission.enrollment.entry_date).to eq(Date.current)

          clh = submission.enrollment.as_warehouse.enrollment_location_histories.first
          expect(clh.client_id).to eq(submission.enrollment.client.id)
          expect(clh.lat).to eq(40.812497)
          expect(clh.lon).to eq(-77.882926)
          expect(clh.located_on).to eq(Date.yesterday)
          expect(clh.located_at).to eq(submission.submitted_at)
        end

        it 'should still work when auto enter is turned on in the project' do
          Hmis::ProjectAutoEnterConfig.create!(project: p1)
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1).
            and change(ClientLocationHistory::Location, :count).by(1)
        end
      end

      context 'when geolocation is not available' do
        let!(:submission) do
          data = {
            'Client.firstName': 'bar',
            'Geolocation.coordinates': { 'notCollectedReason': 'error' }.to_json,
          }.stringify_keys
          create(:hmis_external_form_submission, raw_data: data, definition: definition)
        end

        it 'should not save a save CLH record' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
          end.to change(Hmis::Hud::Client, :count).by(1).
            and change(Hmis::Hud::Enrollment, :count).by(1).
            and not_change(ClientLocationHistory::Location, :count)
        end
      end
    end
  end
end
