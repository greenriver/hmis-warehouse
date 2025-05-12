###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
  include_context 'file upload setup'

  before(:each) do
    hmis_login(user)
  end
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:c1) { create :hmis_hud_client_with_warehouse_client, data_source: ds1, user: u1 }

  let(:query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          hudChronic
        }
      }
    GRAPHQL
  end

  shared_context 'with enrollment setup' do |times_homeless:, exit_date: nil|
    let!(:enrollment) do
      create(:hmis_hud_enrollment,
             data_source: ds1,
             project: p1,
             client: c1,
             DisablingCondition: 1,
             MonthsHomelessPastThreeYears: 112, # see MonthsHomelessPastThreeYears enum
             TimesHomelessPastThreeYears: times_homeless,
             exit_date: exit_date)
    end
  end

  shared_examples 'chronic status check' do |expected_status:|
    before do
      # simulate periodic processing of chronic status
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: enrollment.id).each(&:rebuild_service_history!)
      GrdaWarehouse::ChEnrollment.maintain!
    end
    it 'returns the correct chronic status' do
      response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'client', 'hudChronic')).to eq(expected_status)
    end
  end

  describe 'HUD chronic status determination' do
    context 'when client has less than four months homeless' do
      include_context 'with enrollment setup', times_homeless: 3
      include_examples 'chronic status check', expected_status: false
    end

    context 'when client has four or months homeless' do
      include_context 'with enrollment setup', times_homeless: 4
      include_examples 'chronic status check', expected_status: true

      context 'and client has moved to permanent housing' do
        before do
          ph_project = create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 13
          create(:hmis_hud_enrollment, data_source: ds1, project: ph_project, move_in_date: 2.days.ago, client: c1)
        end
        include_examples 'chronic status check', expected_status: false
      end

      context 'but has exited' do
        before do
          create(:hmis_base_hud_exit, enrollment: enrollment, data_source: ds1)
        end
        include_examples 'chronic status check', expected_status: false
      end
    end
  end
end
