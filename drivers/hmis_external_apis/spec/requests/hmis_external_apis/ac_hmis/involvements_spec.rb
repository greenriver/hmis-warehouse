###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::InvolvementsController, type: :request do
  let(:headers) do
    conf = create(:inbound_api_configuration, internal_system: create(:internal_system, :involvements))
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

  describe 'client involvement' do
    it 'works minimally' do
      api_get(:client, { start_date: '2000-01-01', end_date: '2000-01-10', mci_ids: [12345] })

      expect(response.status).to eq 200
      expect(JSON.parse(response.body)['involvements']).to eq []
    end
  end

  describe 'program involvement' do
    let(:project) do
      ds = create(:source_data_source, id: 1)
      org = create(:hud_organization, data_source_id: ds.id)
      create(:hud_project, data_source_id: ds.id, OrganizationID: org.OrganizationID)
    end

    it 'works minimally' do
      api_get(:program, { start_date: '2000-01-01', end_date: '2000-01-10', program_id: project.project_id })

      expect(response.status).to eq 200
      expect(JSON.parse(response.body)['involvements']).to eq []
    end
  end
end
