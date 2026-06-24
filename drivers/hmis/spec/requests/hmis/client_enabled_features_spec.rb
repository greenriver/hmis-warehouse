###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Client enabledFeatures', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          enabledFeatures
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  before(:each) { hmis_login(user) }

  it 'includes CASE_NOTE when an active CASE_NOTE form instance exists for the data source' do
    create(:hmis_form_instance, data_source: ds1, entity: p1, role: :CASE_NOTE)
    response, result = post_graphql(id: c1.id) { query }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'client', 'enabledFeatures')).to eq(['CASE_NOTE'])
  end

  it 'includes FILE when an active FILE form instance exists for the data source' do
    create(:hmis_form_instance, data_source: ds1, entity: p1, role: :FILE)
    response, result = post_graphql(id: c1.id) { query }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'client', 'enabledFeatures')).to eq(['FILE'])
  end

  it 'does not include features from form instances that belong to another data source' do
    ds2 = create(:hmis_data_source)
    create(:hmis_form_instance, data_source: ds2, entity: nil, role: :CASE_NOTE)
    create(:hmis_form_instance, data_source: ds2, entity: nil, role: :FILE)
    response, result = post_graphql(id: c1.id) { query }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'client', 'enabledFeatures')).to eq([])
  end
end
