###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e2) do
    enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1)
    enrollment.save_in_progress
    enrollment
  end
  let(:new_entry_date) { Date.today - 7.days }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation DeleteEnrollment($input: DeleteEnrollmentInput!) {
        deleteEnrollment(input: $input) {
          enrollment {
            id
            entryDate
            relationshipToHoH
            client {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should not delete an enrollment that is not in progress' do
    response, result = post_graphql(input: { id: e1.id }) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'deleteEnrollment', 'enrollment')
      errors = result.dig('data', 'deleteEnrollment', 'errors')
      expect(enrollment).to be_present
      expect(errors).to contain_exactly(include('fullMessage' => 'Completed enrollments can not be deleted. Please exit the client instead.'))
      expect(Hmis::Hud::Enrollment.all).to contain_exactly(
        have_attributes(id: e1.id),
        have_attributes(id: e2.id),
      )
    end
  end

  it 'should delete an enrollment that is in progress' do
    response, result = post_graphql(input: { id: e2.id }) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'deleteEnrollment', 'enrollment')
      errors = result.dig('data', 'deleteEnrollment', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.all).to contain_exactly(
        have_attributes(id: e1.id),
      )
    end
  end

  it 'should throw error if unauthorized' do
    remove_permissions(hmis_user, :can_delete_enrollments)
    expect { post_graphql(input: { id: e2.id }) { mutation } }.to raise_error(HmisErrors::ApiError)
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
