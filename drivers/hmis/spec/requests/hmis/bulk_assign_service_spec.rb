###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'BulkAssignService', type: :request do
  include_context 'hmis base setup'
  include_context 'hmis service setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation BulkAssignService($input: BulkAssignServiceInput!) {
        bulkAssignService(input: $input) {
          success
        }
      }
    GRAPHQL
  end

  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500' }
  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let(:bednight_service_type) { Hmis::Hud::CustomServiceType.find_by(hud_record_type: 200) }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }

  let!(:c2) { create :hmis_hud_client, data_source: ds1 }
  let!(:c2_e1) { create :hmis_hud_enrollment, data_source: ds1, client: c2, project: p1, entry_date: 1.week.ago }
  let!(:c2_e1_dup) { create :hmis_hud_enrollment, data_source: ds1, client: c2, project: p1, entry_date: 6.days.ago }

  def perform_mutation(project_id: p1.id, date_provided: Date.current, client_ids: [c1.id, c2.id], service_type_id: bednight_service_type.id, coc_code: nil)
    input = {
      project_id: project_id,
      date_provided: date_provided,
      client_ids: client_ids,
      service_type_id: service_type_id,
      coc_code: coc_code,
    }
    post_graphql(input: input) { mutation }
    # expect(response.status).to eq(200), result.inspect
  end

  before(:each) do
    hmis_login(user)
  end

  it 'assigns services and enrolls unenrolled clients (HUD Service)' do
    expect { perform_mutation }.
      # c1 was enrolled
      to change(c1.enrollments, :count).by(1).
      # c1 was assigned a service
      and change(c1.services, :count).by(1).
      # c2 was not re-enrolled
      and change(c2.enrollments, :count).by(0).
      # c2 was assigned a service on their existing enrollment
      and change(c2_e1.services, :count).by(1).
      # c2 dup enrollment not affected
      and change(c2_e1_dup.services, :count).by(0)

    generated_enrollment = c1.enrollments.first
    expect(generated_enrollment.valid?).to eq(true)
    expect(generated_enrollment.enrollment_coc).to eq(pc1.coc_code)
    expect(generated_enrollment.relationship_to_hoh).to eq(1)
    expect(generated_enrollment.household_id).to be_present
  end

  it 'assigns services and enrolls unenrolled clients (Custom Service)' do
    expect { perform_mutation(service_type_id: cst1.id) }.
      # c1 was enrolled
      to change(c1.enrollments, :count).by(1).
      # c1 was assigned a service
      and change(c1.custom_services, :count).by(1).
      # c2 was not re-enrolled
      and change(c2.enrollments, :count).by(0).
      # c2 was assigned a service on their existing enrollment
      and change(c2_e1.custom_services, :count).by(1).
      # c2 dup enrollment not affected
      and change(c2_e1_dup.custom_services, :count).by(0)
  end

  it 'assigns a unit when enrolling a new client, if project is set up with units' do
    create(:hmis_unit, project: p1)
    perform_mutation
    expect(c1.enrollments.first.active_unit_occupancy).to be_present
  end

  it 'assigns service to an existing WIP enrollment' do
    c2_e1.save_in_progress!
    expect { perform_mutation }.to change(c2_e1.services, :count).by(1)

    expect(c2_e1.in_progress?).to eq(true) # wip status unchanged
    expect(c1.enrollments.first.valid?).to eq(true)
  end

  it 'generates enrollment with correct ProjectCoC' do
    second_coc = create(:hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-501')

    perform_mutation(coc_code: second_coc.coc_code)

    expect(c1.enrollments.first.valid?).to eq(true)
    expect(c1.enrollments.first.enrollment_coc).to eq(second_coc.coc_code)
  end

  it 'does not choose exited enrollment' do
    old_enrollment = create(:hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, entry_date: 1.year.ago, exit_date: 10.months.ago)

    expect { perform_mutation(service_type_id: cst1.id) }.
      # c1 was enrolled
      to change(c1.enrollments, :count).by(1).
      and change(old_enrollment.services, :count).by(0)
  end

  describe 'failure scenarios' do
    it 'fails if user lacks can_view_project' do
      remove_permissions(access_control, :can_view_project)
      expect_gql_error(perform_mutation, message: 'access denied')
    end

    it 'fails if user lacks can_edit_enrollments' do
      remove_permissions(access_control, :can_edit_enrollments)
      expect_gql_error(perform_mutation, message: 'access denied')
    end

    it 'fails if user lacks can_view_clients' do
      remove_permissions(access_control, :can_view_clients)
      expect_gql_error(perform_mutation, message: 'access denied')
    end

    it 'fails if user lacks can_enroll_clients' do
      remove_permissions(access_control, :can_enroll_clients)
      expect_gql_error(perform_mutation, message: 'access denied')
    end

    it 'fails if client ids are not found' do
      expect_gql_error(perform_mutation(client_ids: [c1.id, '23423']), message: 'access denied')
    end

    it 'fails if project has units and they are all occupied' do
      unit = create(:hmis_unit, project: p1)
      create(:hmis_unit_occupancy, enrollment: c2_e1, unit: unit)

      expect_gql_error(perform_mutation, message: 'no available units')
    end

    it 'fails if project has no coc codes' do
      p1.project_cocs.destroy_all

      expect_gql_error(perform_mutation, message: 'CoC Code required')
    end

    it 'fails if passed invalid coc code' do
      create(:hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-501')

      expect_gql_error(perform_mutation(coc_code: 'MA-100'), message: 'Invalid CoC Code')
    end
  end
end
