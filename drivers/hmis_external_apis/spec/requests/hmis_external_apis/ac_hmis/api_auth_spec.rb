###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::InvolvementsController, type: :request do
  it 'fails with no api key' do
    get hmis_external_apis_client_involvements_path, params: {}, as: :json

    expect(response.status).to eq 401
  end

  it 'fails with invalid api key' do
    headers = { 'Authorization' => 'Bearer 12345' }

    get hmis_external_apis_client_involvements_path, params: {}, headers: headers, as: :json

    expect(response.status).to eq 401
  end

  it 'fails with valid key that is for a different system' do
    conf = create(:inbound_api_configuration, internal_system: create(:internal_system, :referrals))

    headers = { 'Authorization' => "Bearer #{conf.plain_text_api_key}" }

    get hmis_external_apis_client_involvements_path, params: {}, headers: headers, as: :json

    expect(response.status).to eq 401
  end

  it 'does not have auth failure with valid api key' do
    conf = create(:inbound_api_configuration, internal_system: create(:internal_system, :involvements))

    headers = { 'Authorization' => "Bearer #{conf.plain_text_api_key}" }

    get hmis_external_apis_client_involvements_path, params: {}, headers: headers, as: :json

    expect(response.status).to_not eq 401
  end

  it 'does not have auth failure with valid api key with some forgiveness' do
    conf = create(:inbound_api_configuration, internal_system: create(:internal_system, :involvements))

    headers = { 'Authorization' => " bearer  #{conf.plain_text_api_key.upcase} " }

    get hmis_external_apis_client_involvements_path, params: {}, headers: headers, as: :json

    expect(response.status).to_not eq 401
  end
end
