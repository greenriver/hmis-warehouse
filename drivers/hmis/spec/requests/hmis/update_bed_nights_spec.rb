###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Update bed night mutation', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      mutation UpdateBedNights($input: UpdateBedNightsInput!) {
        updateBedNights(input: $input) {
          success
          errors {
            id
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_view_enrollment_details, :can_view_clients]) }
  let(:enrollments) do
    5.times.map do
      client = create :hmis_hud_client, data_source: ds1, user: u1
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, relationship_to_ho_h: 1
    end
  end
  let(:today) { Date.current }

  before(:each) do
    hmis_login(user)
  end

  context 'when adding bed nights' do
    let(:mutation_input) do
      {
        "input": {
          "projectId": p1.id,
          "enrollmentIds": enrollments.map { |e| e.id.to_s },
          "action": 'ADD',
          "bedNightDate": today.to_s(:db),
        },
      }
    end

    it 'creates services' do
      services = Hmis::Hud::Service.bed_nights.where(EnrollmentID: enrollments.map(&:enrollment_id))
      versions = GrdaWarehouse.paper_trail_versions.where(enrollment_id: enrollments.map(&:id))
      expect do
        response, = post_graphql(mutation_input) { query }
        expect(response.status).to eq 200
      end.to change(services, :count).by(enrollments.size).
        and change(versions, :count).by(enrollments.size).
        and make_database_queries(count: 50..100)
    end
  end

  context 'when removing bed nights' do
    let(:mutation_input) do
      {
        "input": {
          "projectId": p1.id,
          "enrollmentIds": enrollments.map { |e| e.id.to_s },
          "action": 'REMOVE',
          "bedNightDate": today.to_s(:db),
        },
      }
    end

    before(:each) do
      enrollments.each do |enrollment|
        create(:hmis_hud_service, enrollment: enrollment, record_type: 200, data_source: ds1, user: u1, date_provided: today)
      end
    end

    it 'destroys services' do
      services = Hmis::Hud::Service.bed_nights.where(EnrollmentID: enrollments.map(&:enrollment_id))
      versions = GrdaWarehouse.paper_trail_versions.where(enrollment_id: enrollments.map(&:id))
      expect do
        response, = post_graphql(mutation_input) { query }
        expect(response.status).to eq 200
      end.to change(services, :count).by(enrollments.size * -1).
        and change(versions, :count).by(enrollments.size).
        and make_database_queries(count: 50..100)
    end
  end
end
