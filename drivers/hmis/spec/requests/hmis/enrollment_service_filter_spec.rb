###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
  include_context 'hmis service setup'

  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1 }
  let!(:hud_s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, date_updated: Date.current - 1.week }
  let(:s1) { Hmis::Hud::HmisService.find_by(owner: hud_s1) }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:query) do
    <<~GRAPHQL
      query EnrollmentServices($id: ID!, $filters: ServicesForEnrollmentFilterOptions!) {
        enrollment(id: $id) {
          services(filters: $filters) {
            nodes {
              #{scalar_fields(Types::HmisSchema::Service)}
            }
          }
        }
      }
    GRAPHQL
  end

  before(:each) do
    hmis_login(user)
  end

  def search(**input)
    aggregate_failures 'checking response' do
      response, result = post_graphql(input) { query }
      expect(response.status).to eq 200
      services = result.dig('data', 'enrollment', 'services', 'nodes')
      yield services
    end
  end

  it 'should filter correctly by service category' do
    category_id = s1.custom_service_type.category.id.to_s
    search(id: e1.id.to_s, filters: { service_category: [category_id] }) do |services|
      expect(services).to contain_exactly(include('id' => s1.id.to_s))
    end
    search(id: e1.id.to_s, filters: { service_category: ['0'] }) do |services|
      expect(services).to be_empty
    end
    search(id: e1.id.to_s, filters: { service_category: ['0', category_id] }) do |services|
      expect(services).to contain_exactly(include('id' => s1.id.to_s))
    end
  end

  it 'should filter correctly by service type' do
    service_type_id = s1.custom_service_type.id.to_s
    search(id: e1.id.to_s, filters: { service_type: [service_type_id] }) do |services|
      expect(services).to contain_exactly(include('id' => s1.id.to_s))
    end
    search(id: e1.id.to_s, filters: { service_type: ['0'] }) do |services|
      expect(services).to be_empty
    end
    search(id: e1.id.to_s, filters: { service_type: ['0', service_type_id] }) do |services|
      expect(services).to contain_exactly(include('id' => s1.id.to_s))
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
