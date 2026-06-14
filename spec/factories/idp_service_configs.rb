###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :idp_service_config, class: 'Idp::ServiceConfig' do
    connector_id { 'keycloak' }
    name { 'Keycloak Development' }
    api_url { 'http://keycloak.test:8080' }
    service_token { 'test-token-secret-key' }
    org_id { 'org-123456' }
    project_id { 'proj-789012' }
    additional_config { { client_id: 'rails-service-account', realm: 'openpath' } }
    active { true }
  end
end
