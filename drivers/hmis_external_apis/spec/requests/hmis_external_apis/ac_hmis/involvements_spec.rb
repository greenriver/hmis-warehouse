###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::InvolvementsController, type: :request do
  let(:headers) do
    internal_system = HmisExternalApis::InternalSystem.find_by(name: 'Involvements')
    internal_system ||= create(:internal_system, :involvements)
    conf = create(:inbound_api_configuration, internal_system: internal_system)
    { 'Authorization' => "Bearer #{conf.plain_text_api_key}" }
  end

  def api_get(endpoint, params)
    case endpoint
    when :program
      get hmis_external_apis_program_involvements_path, params: params, headers: headers, as: :json
    when :client
      get hmis_external_apis_client_involvements_path, params: params, headers: headers, as: :json
    else
      raise "Invalid endpoint of #{endpoint}"
    end
  end

  let!(:ds) { create(:hmis_data_source) }
  let!(:org) { create(:hmis_hud_organization, data_source: ds) }
  let!(:project) { create(:hmis_hud_project, data_source: ds, organization: org) }

  describe 'client involvement' do
    it 'works minimally' do
      api_get(:client, { start_date: '2000-01-01', end_date: '2000-01-10', mci_ids: [12345] })

      expect(response.status).to eq 200
      expect(JSON.parse(response.body)['involvements']).to eq []
      expect(HmisExternalApis::ExternalRequestLog.count).to eq(1)
      expect(HmisExternalApis::ExternalRequestLog.first.response).to match(/involvements/)
    end
  end

  describe 'program involvement' do
    it 'works minimally' do
      api_get(:program, { start_date: '2000-01-01', end_date: '2000-01-10', program_ids: [project.project_id] })

      expect(response.status).to eq 200
      expect(JSON.parse(response.body)['involvements']).to eq []
      expect(HmisExternalApis::ExternalRequestLog.count).to eq(1)
      expect(HmisExternalApis::ExternalRequestLog.first.response).to match(/involvements/)
    end
  end
end
