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
          assessment {
            #{scalar_fields(Types::HmisSchema::Assessment)}
            customForm {
              #{scalar_fields(Types::HmisSchema::CustomForm)}
              definition {
                id
              }
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  def mutate(**kwargs)
    response, result = post_graphql(**kwargs) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      assessment = result.dig('data', 'deleteAssessment', 'assessment')
      errors = result.dig('data', 'deleteAssessment', 'errors')
      yield assessment, errors
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

      mutate(input: { id: a1.id }) do |assessment, errors|
        expect(assessment).to be_present
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

      mutate(input: { id: a1.id }) do |assessment, errors|
        expect(assessment).to be_nil
        expect(errors).to contain_exactly(include('type' => 'not_allowed'))
      end

      expect(Hmis::Hud::CustomAssessment.all).to include(have_attributes(id: a1.id))
    end
  end

  # Don't allow deletion of submitted intake assessments
  wip_and_submitted.each do |key, name, action|
    it "should handle deleting a #{name} intake assessment" do
      action.call(a1)
      fd1.update(role: 'INTAKE')

      mutate(input: { id: a1.id }) do |assessment, errors|
        if key == :wip
          expect(assessment).to be_present
          expect(errors).to be_empty
          expect(Hmis::Hud::CustomAssessment.all).not_to include(have_attributes(id: a1.id))
        elsif key == :submitted
          expect(assessment).to be_nil
          expect(errors).to contain_exactly(include('type' => 'not_allowed'))
          expect(Hmis::Hud::CustomAssessment.all).to include(have_attributes(id: a1.id))
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

      mutate(input: { id: a1.id }) do |assessment, errors|
        expect(assessment).to be_present
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
