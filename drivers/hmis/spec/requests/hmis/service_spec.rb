###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  include_context 'hmis service setup'

  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1 }

  let!(:hud_s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, date_updated: Date.current - 1.week }
  let(:s1) { Hmis::Hud::HmisService.find_by(owner: hud_s1) }

  let!(:custom_s2) { create(:hmis_custom_service, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1) }
  let(:s2) { Hmis::Hud::HmisService.find_by(owner: custom_s2) }

  let(:query) do
    <<~GRAPHQL
      query Service($id: ID!) {
        service(id: $id) {
          id
          serviceType {
            id
            name
            hud
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1) }
  before(:each) { hmis_login(user) }

  it 'returns the correct service type for a HUD service' do
    response, result = post_graphql(id: s1.id) { query }
    expect(response.status).to eq(200), result.inspect
    service = result.dig('data', 'service')
    expect(service).to be_present
    expected_service_type = Hmis::Hud::CustomServiceType.find_by(hud_record_type: hud_s1.RecordType, hud_type_provided: hud_s1.TypeProvided, data_source_id: ds1)
    expect(service['serviceType']['id']).to eq(expected_service_type.id.to_s)
    expect(service['serviceType']['name']).to eq(expected_service_type.name.to_s)
    expect(service['serviceType']['hud']).to eq(true)
  end

  it 'returns the correct service type for a fully custom service' do
    response, result = post_graphql(id: s2.id) { query }
    expect(response.status).to eq(200), result.inspect
    service = result.dig('data', 'service')
    expect(service).to be_present
    expect(service['serviceType']['id']).to eq(cst1.id.to_s)
    expect(service['serviceType']['name']).to eq(cst1.name)
    expect(service['serviceType']['hud']).to eq(false)
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
