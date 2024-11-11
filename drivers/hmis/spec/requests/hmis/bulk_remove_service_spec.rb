###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'BulkRemoveService', type: :request do
  include_context 'hmis base setup'
  include_context 'hmis service setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation BulkRemoveService($projectId: ID!, $serviceIds: [ID!]!) {
        bulkRemoveService(projectId: $projectId, serviceIds: $serviceIds) {
          success
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 1.week.ago }
  let!(:s1) { create :hmis_hud_service_bednight, data_source: ds1, enrollment: e1, date_provided: 5.days.ago }

  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 1.week.ago }
  let!(:s2) { create :hmis_hud_service_bednight, data_source: ds1, enrollment: e2, date_provided: 3.days.ago }

  def perform_mutation(service_ids:, project_id: p1.id.to_s)
    input = {
      project_id: project_id,
      service_ids: service_ids,
    }
    post_graphql(input) { mutation }
  end

  before(:each) do
    hmis_login(user)
  end

  it 'remove services' do
    hmis_service_ids = Hmis::Hud::HmisService.where(owner: [s1, s2]).map(&:id)

    expect do
      response, result = perform_mutation(service_ids: hmis_service_ids)
      expect(response.status).to eq(200), result.inspect
    end.to change(Hmis::Hud::Service, :count).by(-2).and not_change(Hmis::Hud::Enrollment, :count)

    expect(s1.reload).to be_deleted
    expect(s2.reload).to be_deleted
  end

  it 'ignores service IDs that are not found' do
    expect do
      response, result = perform_mutation(service_ids: ['9999999'])
      expect(response.status).to eq(200), result.inspect
    end.not_to change(Hmis::Hud::Service, :count)
  end

  it 'ignores service IDs that are in another project' do
    other_service = create(:hmis_hud_service_bednight, data_source: ds1)
    other_service_id = Hmis::Hud::HmisService.find_by(owner: other_service).id

    expect do
      response, result = perform_mutation(service_ids: [other_service_id])
      expect(response.status).to eq(200), result.inspect
    end.not_to change(Hmis::Hud::Service, :count)
  end

  describe 'failure scenarios' do
    # give user access to everything at p2. We will test removing access from p1.
    let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }
    let!(:p2_access_control) { create_access_control(hmis_user, p2) }

    let!(:service_ids) { Hmis::Hud::HmisService.where(owner: [s1, s2]).map(&:id) }

    it 'fails if user lacks can_view_project at p1' do
      remove_permissions(access_control, :can_view_project)
      expect_access_denied perform_mutation(service_ids: service_ids)
    end

    it 'fails if user lacks can_edit_enrollments at p1' do
      remove_permissions(access_control, :can_edit_enrollments)
      expect_access_denied perform_mutation(service_ids: service_ids)
    end
  end
end
