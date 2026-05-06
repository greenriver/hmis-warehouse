# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 2.weeks.ago }
  let!(:a1) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 5 }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation DeleteAssessment($input: DeleteAssessmentInput!) {
        deleteAssessment(input: $input) {
          assessmentId
          #{error_fields}
        }
      }
    GRAPHQL
  end

  def mutate(**kwargs)
    response, result = post_graphql(**kwargs) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      assessment_id = result.dig('data', 'deleteAssessment', 'assessmentId')
      errors = result.dig('data', 'deleteAssessment', 'errors')
      yield assessment_id, errors
    end
  end

  wip_and_submitted = [
    [:wip, 'WIP', lambda(&:save_in_progress), :can_edit_enrollments],
    [:submitted, 'submitted', lambda(&:save_not_in_progress), :can_delete_assessments],
  ]

  # Normal deletion tests
  wip_and_submitted.each do |_key, name, action|
    it "should delete a #{name} assessment successfully" do
      action.call(a1)
      expect(Hmis::Hud::CustomAssessment.all).to include(have_attributes(id: a1.id))

      mutate(input: { id: a1.id }) do |assessment_id, errors|
        expect(assessment_id).to be_present
        expect(errors).to be_empty
      end

      expect(Hmis::Hud::CustomAssessment.all).not_to include(have_attributes(id: a1.id))
    end
  end

  # Permissions tests
  wip_and_submitted.each do |_key, name, action, permission|
    it "should not delete a #{name} assessment if not allowed due to permissions" do
      remove_permissions(access_control, permission)
      action.call(a1)

      expect_gql_error post_graphql(input: { id: a1.id }) { mutation }
      expect(Hmis::Hud::CustomAssessment.all).to include(have_attributes(id: a1.id))
    end
  end

  # Deleting non-wip intakes should require enrollment deletion permissions
  wip_and_submitted.each do |key, name, action|
    it "should handle deleting #{name} intake assessment based on whether user can delete enrollments" do
      remove_permissions(access_control, :can_delete_enrollments)
      action.call(a1)
      a1.update(data_collection_stage: 1) # intake

      if key == :submitted
        expect_gql_error post_graphql(input: { id: a1.id }) { mutation }
      else
        mutate(input: { id: a1.id }) do |assessment_id, errors|
          a1.reload
          e1.reload
          expect(assessment_id).to be_present
          expect(errors).to be_empty
          expect(a1.date_deleted).to be_present
          expect(e1.date_deleted).to be_present
        end
      end
    end
  end

  # Deleting intakes should delete the enrollment
  wip_and_submitted.each do |_key, name, action|
    it "should handle deleting a #{name} intake assessment" do
      action.call(a1)
      a1.update(data_collection_stage: 1) # intake

      mutate(input: { id: a1.id }) do |assessment_id, errors|
        a1.reload
        e1.reload
        expect(assessment_id).to be_present
        expect(errors).to be_empty
        expect(a1.date_deleted).to be_present
        expect(e1.date_deleted).to be_present
      end
    end
  end

  # Deleting intakes should only delete the enrollment if there are not other intakes
  wip_and_submitted.each do |_key, name, action|
    it "should handle deleting a #{name} intake assessment with multiple intakes" do
      a2 = create :hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 5
      action.call(a1)
      action.call(a2)
      a1.update(data_collection_stage: 1) # intake
      a2.update(data_collection_stage: 1) # intake

      mutate(input: { id: a1.id }) do |assessment_id, errors|
        a1.reload
        a2.reload
        e1.reload
        expect(assessment_id).to be_present
        expect(errors).to be_empty
        expect(a1.date_deleted).to be_present
        expect(a2.date_deleted).to be_nil
        expect(e1.date_deleted).to be_nil
      end
    end
  end

  # Deleting HoH intake deletes the whole household: all members' enrollments and their intake assessments.
  context 'when deleting intake for a multi-member household' do
    let!(:a1) { create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 1) }

    let!(:c2) { create(:hmis_hud_client, data_source: ds1) }
    let!(:e2) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, household_id: e1.household_id, relationship_to_ho_h: 5) }
    let!(:a2) { create(:hmis_custom_assessment, data_source: ds1, enrollment: e2, client: c2, data_collection_stage: 1) }

    let!(:c3) { create(:hmis_hud_client, data_source: ds1) }
    let!(:e3) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, household_id: e1.household_id, relationship_to_ho_h: 8) }
    let!(:a3) { create(:hmis_custom_assessment, data_source: ds1, enrollment: e3, client: c3, data_collection_stage: 1) }

    shared_examples 'fully deletes the household' do
      it "returns success and deletes all members' intake assessments and enrollments" do
        mutate(input: { id: a1.id }) do |assessment_id, errors|
          expect(assessment_id).to be_present
          expect(errors).to be_empty
          expect(a1.reload.date_deleted).to be_present
          expect(a2.reload.date_deleted).to be_present
          expect(a3.reload.date_deleted).to be_present
          expect(e1.reload.date_deleted).to be_present
          expect(e2.reload.date_deleted).to be_present
          expect(e3.reload.date_deleted).to be_present
        end
      end
    end

    wip_and_submitted.each do |_key, name, action|
      context "with #{name} HoH and household member intakes" do
        before do
          action.call(a1)
          action.call(a2)
          action.call(a3)
        end

        it_behaves_like 'fully deletes the household'
      end
    end

    context 'when deleting WIP HoH intake while another member already has a submitted intake' do
      before do
        a1.save_in_progress
        a2.save_not_in_progress
        a3.save_in_progress
      end

      it_behaves_like 'fully deletes the household'
    end

    context 'when deleting submitted HoH intake while another member only has WIP intake' do
      before do
        a1.save_not_in_progress
        a2.save_in_progress
        a3.save_not_in_progress
      end

      it_behaves_like 'fully deletes the household'
    end

    wip_and_submitted.each do |_key, name, action|
      it "only deletes that member's enrollment when deleting a #{name} non-HoH intake assessment" do
        action.call(a2)

        mutate(input: { id: a2.id }) do |assessment_id, errors|
          expect(assessment_id).to be_present
          expect(errors).to be_empty
          # Inkake and enrollment for non-HoH are both deleted
          expect(a2.reload.date_deleted).to be_present
          expect(e2.reload.date_deleted).to be_present
          # HoH intake and enrollment were not touched
          expect(a1.reload.date_deleted).to be_nil
          expect(e1.reload.date_deleted).to be_nil
          # Other HHM intake and enrollment were not touched
          expect(a3.reload.date_deleted).to be_nil
          expect(e3.reload.date_deleted).to be_nil
        end
      end
    end
  end

  it 'should un-exit when deleting a submitted exit assessment' do
    a1.save_not_in_progress
    a1.update!(data_collection_stage: 3) # exit
    a1.form_processor.update!(
      exit: create(:hmis_hud_exit, enrollment: e1, client: c1, user: u1, data_source: ds1),
    )

    mutate(input: { id: a1.id }) do |assessment_id, errors|
      expect(assessment_id).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::CustomAssessment.all).not_to include(have_attributes(id: a1.id))
      e1.reload
      expect(e1.exit).to be_nil
      expect(e1.exit_date).to be_nil
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
