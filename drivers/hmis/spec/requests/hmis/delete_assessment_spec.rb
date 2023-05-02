###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: 2.weeks.ago }
  let!(:fd1) { create :hmis_form_definition, role: 'UPDATE' }
  let!(:a1) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1, user: u1 }
  let!(:cf1) { create :hmis_form_custom_form, definition: fd1, owner: a1 }

  before(:each) do
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
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
    [:wip, 'WIP', ->(a) { a.save_in_progress }, :can_edit_enrollments],
    [:submitted, 'submitted', ->(a) { a.save_not_in_progress }, :can_delete_assessments],
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
      remove_permissions(hmis_user, permission)
      action.call(a1)

      mutate(input: { id: a1.id }) do |assessment_id, errors|
        expect(assessment_id).to be_nil
        expect(errors).to contain_exactly(include('type' => 'not_allowed'))
      end

      expect(Hmis::Hud::CustomAssessment.all).to include(have_attributes(id: a1.id))
    end
  end

  # Deleting non-wip intakes should require enrollment deletion permissions
  wip_and_submitted.each do |key, name, action|
    it "should handle deleting #{name} intake assessment based on whether user can delete enrollments" do
      remove_permissions(hmis_user, :can_delete_enrollments)
      action.call(a1)
      fd1.update(role: 'INTAKE')

      mutate(input: { id: a1.id }) do |assessment_id, errors|
        a1.reload
        e1.reload
        if key == :wip
          expect(assessment_id).to be_present
          expect(errors).to be_empty
          expect(a1.date_deleted).to be_present
          expect(e1.date_deleted).to be_present
        elsif key == :submitted
          expect(assessment_id).to be_nil
          expect(errors).to contain_exactly(include('type' => 'not_allowed'))
          expect(a1.date_deleted).to be_nil
          expect(e1.date_deleted).to be_nil
        end
      end
    end
  end

  # Deleting intakes should delete the enrollment
  wip_and_submitted.each do |key, name, action|
    it "should handle deleting a #{name} intake assessment" do
      action.call(a1)
      fd1.update(role: 'INTAKE')

      mutate(input: { id: a1.id }) do |assessment_id, errors|
        a1.reload
        e1.reload
        if key == :wip
          expect(assessment_id).to be_present
          expect(errors).to be_empty
          expect(a1.date_deleted).to be_present
          expect(e1.date_deleted).to be_present
        elsif key == :submitted
          expect(assessment_id).to be_present
          expect(errors).to be_empty
          expect(a1.date_deleted).to be_present
          expect(e1.date_deleted).to be_present
        end
      end
    end
  end

  # Client should be exited when deleting an exit assessment
  wip_and_submitted.each do |_key, name, action|
    it "should handle deleting a #{name} intake assessment" do
      action.call(a1)
      fd1.update(role: 'EXIT')
      create(:hmis_hud_exit, enrollment: e1, client: c1, user: u1, data_source: ds1)

      mutate(input: { id: a1.id }) do |assessment_id, errors|
        expect(assessment_id).to be_present
        expect(errors).to be_empty
        expect(Hmis::Hud::CustomAssessment.all).not_to include(have_attributes(id: a1.id))
        expect(e1.exit).to be_nil
        expect(e1.exit_date).to be_nil
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
