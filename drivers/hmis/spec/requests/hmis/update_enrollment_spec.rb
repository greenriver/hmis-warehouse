require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let(:u2) do
    user2 = create(:user).tap { |u| u.add_viewable(ds1) }
    hmis_user2 = Hmis::User.find(user2.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) }
    Hmis::Hud::User.from_user(hmis_user2)
  end
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u2 }
  let(:new_entry_date) { Date.today - 7.days }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateEnrollment($input: UpdateEnrollmentInput!) {
        updateEnrollment(input: $input) {
          enrollment {
            id
            entryDate
            relationshipToHoH
            client {
              id
            }
            dateUpdated
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

  describe 'with edit access' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
    end

    it 'should update enrollment correctly' do
      prev_date_updated = e2.date_updated
      expect(e2.user_id).to eq(u2.user_id)

      response, result = post_graphql(
        input: {
          id: e2.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(3).first,
          entry_date: new_entry_date.strftime('%Y-%m-%d'),
        },
      ) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        enrollment = result.dig('data', 'updateEnrollment', 'enrollment')
        errors = result.dig('data', 'updateEnrollment', 'errors')
        expect(e2.reload.date_updated > prev_date_updated).to eq(true)
        expect(e2.reload.user_id).to eq(u1.user_id)
        expect(enrollment).to be_present
        expect(errors).to be_empty
        expect(enrollment).to include(
          'id' => e2.id.to_s,
          'entryDate' => new_entry_date.strftime('%Y-%m-%d'),
          'relationshipToHoH' => Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(3).first,
          'client' => include('id' => c2.id.to_s),
        )
        expect(Hmis::Hud::Enrollment.all).to contain_exactly(
          have_attributes(id: e1.id, personal_id: c1.personal_id, relationship_to_ho_h: 1, entry_date: e1.entry_date),
          have_attributes(id: e2.id, personal_id: c2.personal_id, relationship_to_ho_h: 3, entry_date: new_entry_date),
        )
      end
    end
  end
  describe 'with view access' do
    before(:each) do
      hmis_login(user)
      assign_viewable(view_access_group, p1.as_warehouse, hmis_user)
    end
    it 'should not update enrollment' do
      prev_date_updated = e2.date_updated
      expect(e2.user_id).to eq(u2.user_id)

      response, result = post_graphql(
        input: {
          id: e2.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(3).first,
          entry_date: new_entry_date.strftime('%Y-%m-%d'),
        },
      ) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        enrollment = result.dig('data', 'updateEnrollment', 'enrollment')
        errors = result.dig('data', 'updateEnrollment', 'errors')
        expect(e2.reload.date_updated > prev_date_updated).to eq(false)
        expect(e2.reload.user_id).to eq(u2.user_id)
        expect(enrollment).to be_blank
        expect(errors).to be_present

        expect(Hmis::Hud::Enrollment.all).to contain_exactly(
          have_attributes(id: e1.id, personal_id: c1.personal_id, relationship_to_ho_h: 1, entry_date: e1.entry_date),
          have_attributes(id: e2.id, personal_id: c2.personal_id, relationship_to_ho_h: 2, entry_date: e2.entry_date),
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
