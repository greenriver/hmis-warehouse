###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Sally' }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1 }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, relationship_to_ho_h: 3, household_id: '1', user: u1 }

  before(:each) do
    hmis_login(user)
  end

  let(:test_input) do
    {
      enrollment_id: e3.id,
      relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(1).first,
      confirmed: true,
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateRelationshipToHoH($input: UpdateRelationshipToHoHInput!) {
        updateRelationshipToHoH(input: $input) {
          enrollment {
            id
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

  it 'should change HoH correctly' do
    response, result = post_graphql(input: test_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq(200), result.inspect
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.all).to contain_exactly(
        have_attributes(personal_id: c1.personal_id, relationship_to_ho_h: 99),
        have_attributes(personal_id: c2.personal_id, relationship_to_ho_h: 2),
        have_attributes(personal_id: c3.personal_id, relationship_to_ho_h: 1),
      )
    end
  end

  context 'with Move-in Dates and Move-in Addresses' do
    let(:hoh_move_in_date) { 2.weeks.ago.to_date }
    let!(:hoh) { create :hmis_hud_enrollment, entry_date: 1.month.ago, move_in_date: hoh_move_in_date, relationship_to_ho_h: 1, data_source: ds1, project: p1 }
    let!(:hhm) { create :hmis_hud_enrollment, entry_date: 1.month.ago, relationship_to_ho_h: 2, household_id: hoh.household_id, data_source: ds1, project: p1 }
    let!(:hhm2) { create :hmis_hud_enrollment, entry_date: 1.month.ago, relationship_to_ho_h: 2, household_id: hoh.household_id, data_source: ds1, project: p1 }

    let(:input) do
      {
        enrollment_id: hhm.id,
        relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(1).first,
        confirmed: true,
      }
    end

    def perform_mutation
      response, result = post_graphql(input: input) { mutation }
      expect(response.status).to eq(200), result.inspect
      [hoh, hhm, hhm2].map(&:reload)
    end

    context 'when new HoH enetered before move-in' do
      it 'should transfer move-in date to new HoH' do
        perform_mutation

        # old HoH is cleared
        expect(hoh.relationship_to_ho_h).to eq(99)
        expect(hoh.move_in_date).to be_nil
        # new HoH inherited move-in date
        expect(hhm.relationship_to_ho_h).to eq(1)
        expect(hhm.move_in_date).to eq(hoh_move_in_date)
      end
    end

    context 'when new HoH entered after move-in' do
      before(:each) { hhm.update!(entry_date: hoh_move_in_date + 2.days) }

      it 'should transfer move-in date to new HoH' do
        perform_mutation

        # old HoH is cleared
        expect(hoh.relationship_to_ho_h).to eq(99)
        expect(hoh.move_in_date).to be_nil
        # new HoH inherited Entry Date as move-in date
        expect(hhm.relationship_to_ho_h).to eq(1)
        expect(hhm.move_in_date).to eq(hhm.entry_date)
      end
    end

    context 'when old HoH has Move-in Address' do
      let!(:move_in_address) { create :hmis_move_in_address, enrollment: hoh, data_source: ds1 }

      it 'should transfer Move-in Date and Move-in Address to new HoH' do
        perform_mutation

        # old HoH is cleared
        expect(hoh.relationship_to_ho_h).to eq(99)
        expect(hoh.move_in_date).to be_nil
        expect(hoh.move_in_addresses).to be_empty
        # new HoH inherited Entry Date as move-in date
        expect(hhm.relationship_to_ho_h).to eq(1)
        expect(hhm.move_in_date).to eq(hoh_move_in_date)
        expect(hhm.move_in_addresses.count).to eq(1)
        expect(move_in_address.reload.enrollment).to eq(hhm)
      end
    end

    context 'when there were multiple previous HoHs with Move-in Dates' do
      let(:hoh2_move_in_date) { hoh_move_in_date - 2.days }
      let!(:hoh2) { create :hmis_hud_enrollment, entry_date: 1.month.ago, move_in_date: hoh2_move_in_date, relationship_to_ho_h: 1, data_source: ds1, project: p1, household_id: hoh.household_id, DateCreated: 1.month.ago }

      it 'should choose Move-in Date from prev HoH with earliest creation date' do
        perform_mutation
        hoh2.reload

        # old HoH is cleared
        expect(hoh.relationship_to_ho_h).to eq(99)
        expect(hoh2.relationship_to_ho_h).to eq(99)
        expect(hoh.move_in_date).to be_nil
        expect(hoh2.move_in_date).to be_nil
        # new HoH inherited move-in date from hoh2
        expect(hhm.relationship_to_ho_h).to eq(1)
        expect(hhm.move_in_date).to eq(hoh2_move_in_date)
      end
    end

    context 'when non-hoh members have move-in date values' do
      before(:each) do
        hhm.update!(move_in_date: hoh_move_in_date + 2.days)
        hhm2.update!(move_in_date: hoh_move_in_date + 2.days)
      end

      it 'should clear move-in date values' do
        perform_mutation

        # old HoH is cleared
        expect(hoh.relationship_to_ho_h).to eq(99)
        expect(hoh.move_in_date).to be_nil
        # new hoh
        expect(hhm.relationship_to_ho_h).to eq(1)
        expect(hhm.move_in_date).to eq(hoh_move_in_date) # overrides previous MID
        # other member
        expect(hhm2.move_in_date).to be_nil # clears MID
      end
    end

    it 'should transfer move-in date to new HoH' do
      perform_mutation

      # old HoH is cleared
      expect(hoh.relationship_to_ho_h).to eq(99)
      expect(hoh.move_in_date).to be_nil
      # new HoH inherited move-in date
      expect(hhm.relationship_to_ho_h).to eq(1)
      expect(hhm.move_in_date).to eq(hoh_move_in_date)
    end

    it 'should clear move-in date on other members' do
      perform_mutation

      # old HoH is cleared
      expect(hoh.relationship_to_ho_h).to eq(99)
      expect(hoh.move_in_date).to be_nil
      # new HoH inherited move-in date
      expect(hhm.relationship_to_ho_h).to eq(1)
      expect(hhm.move_in_date).to eq(hoh_move_in_date)
    end
  end

  it 'should support fixing multiple-HoH household' do
    # e1 and e3 are both HoH
    e3.update(relationship_to_hoh: 1)
    # change HoH to e3
    response, result = post_graphql(input: test_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq(200), result.inspect
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(e1.reload.relationship_to_hoh).to eq(99)
      expect(e3.reload.relationship_to_hoh).to eq(1)
    end
  end

  it 'should support fixing no-HoH household' do
    # no hh members are HoH
    e1.update(relationship_to_hoh: 2)
    # change HoH to e3
    response, result = post_graphql(input: test_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq(200), result.inspect
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(e3.reload.relationship_to_hoh).to eq(1)
    end
  end

  it 'should not modify other records if non-HoH change' do
    input = test_input.merge(relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(5).first)

    response, result = post_graphql(input: input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.all).to contain_exactly(
        have_attributes(personal_id: c1.personal_id, relationship_to_ho_h: 1),
        have_attributes(personal_id: c2.personal_id, relationship_to_ho_h: 2),
        have_attributes(personal_id: c3.personal_id, relationship_to_ho_h: 5),
      )
    end
  end

  it 'should warn if unconfirmed' do
    response, result = post_graphql(input: test_input.merge(confirmed: false)) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be nil
      expect(errors).to match([
                                a_hash_including('severity' => 'warning', 'fullMessage' => Hmis::HohChangeHandler.change_hoh_message(c1, c3)),
                              ])
      e3.reload
      expect(e3.relationship_to_ho_h).not_to eq(1)
    end
  end

  it 'should warn if HoH is a child' do
    c3.update(dob: 13.years.ago)
    response, result = post_graphql(input: test_input.merge(confirmed: false)) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be nil
      expect(errors).to match([
                                a_hash_including('severity' => 'warning', 'fullMessage' => Hmis::HohChangeHandler.change_hoh_message(c1, c3)),
                                a_hash_including('severity' => 'warning', 'fullMessage' => Hmis::HohChangeHandler.child_hoh_message),
                              ])
      e3.reload
      expect(e3.relationship_to_ho_h).not_to eq(1)
    end
  end

  it 'should warn if WIP enrollment' do
    e3.save_in_progress!
    response, result = post_graphql(input: test_input.merge(confirmed: false)) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be nil
      expect(errors).to match([
                                a_hash_including('severity' => 'warning', 'fullMessage' => Hmis::HohChangeHandler.change_hoh_message(c1, c3)),
                                a_hash_including('severity' => 'warning', 'fullMessage' => Hmis::HohChangeHandler.incomplete_hoh_message),
                              ])
      e3.reload
      expect(e3.relationship_to_ho_h).not_to eq(1)
    end
  end

  it 'should warn if Exited enrollment' do
    create(:hmis_hud_exit, data_source: ds1, client: c3, enrollment: e3)
    response, result = post_graphql(input: test_input.merge(confirmed: false)) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be nil
      expect(errors).to match([
                                a_hash_including('severity' => 'warning', 'fullMessage' => Hmis::HohChangeHandler.change_hoh_message(c1, c3)),
                                a_hash_including('severity' => 'warning', 'fullMessage' => Hmis::HohChangeHandler.exited_hoh_message),
                              ])
      e3.reload
      expect(e3.relationship_to_ho_h).not_to eq(1)
    end
  end

  it 'should error if unauthorized' do
    remove_permissions(access_control, :can_edit_enrollments)
    expect_gql_error post_graphql(input: test_input) { mutation }, message: 'access denied'
  end

  it 'should error if user does not have access to enrollment' do
    remove_permissions(access_control, :can_view_enrollment_details)
    remove_permissions(access_control, :can_edit_enrollments)
    expect_gql_error post_graphql(input: test_input) { mutation }, message: 'access denied'
  end

  it 'should error if enrollment does not exist' do
    expect_gql_error post_graphql(input: test_input.merge(enrollment_id: '0')) { mutation }, message: 'access denied'
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
