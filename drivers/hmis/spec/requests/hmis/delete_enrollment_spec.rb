require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e2) do
    enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1)
    enrollment.save_in_progress
    enrollment
  end
  let(:new_entry_date) { Date.today - 7.days }
  let(:access_group) { create :edit_access_group }

  before(:each) do
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
    access_group.add_viewable(p1.as_warehouse)
    access_group.add(hmis_user)
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
          errors {
            id
            attribute
            message
            fullMessage
            type
            options
            __typename
          }
        }
      }
    GRAPHQL
  end

  it 'should not delete an enrollment that is not in progress' do
    response, result = post_graphql(input: { id: e1.id }) { mutation }

    expect(response.status).to eq 200
    enrollment = result.dig('data', 'deleteEnrollment', 'enrollment')
    errors = result.dig('data', 'deleteEnrollment', 'errors')
    expect(enrollment).to be_present
    expect(errors).to contain_exactly(include('message' => 'Only in-progress enrollments can be deleted'))
    expect(Hmis::Hud::Enrollment.all).to contain_exactly(
      have_attributes(id: e1.id),
      have_attributes(id: e2.id),
    )
  end

  it 'should delete an enrollment that is in progress' do
    response, result = post_graphql(input: { id: e2.id }) { mutation }

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

RSpec.configure do |c|
  c.include GraphqlHelpers
end
