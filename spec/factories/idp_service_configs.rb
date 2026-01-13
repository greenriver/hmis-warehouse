###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :idp_service_config, class: 'Idp::ServiceConfig' do
    connector_id { 'zitadel' }
    name { 'Zitadel Development' }
    api_url { 'http://zitadel.test:8080' }
    service_token { 'test-token-secret-key' }
    org_id { 'org-123456' }
    project_id { 'proj-789012' }
    active { true }
  end
end
