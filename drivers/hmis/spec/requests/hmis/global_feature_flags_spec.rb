###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetGlobalFeatureFlags {
        globalFeatureFlags {
          id
          esgFundingReportEnabled
        }
      }
    GRAPHQL
  end

  describe 'esgFundingReportEnabled' do
    it 'is false by default' do
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'globalFeatureFlags', 'esgFundingReportEnabled')).to eq(false)
    end

    it 'is true when the feature flag is enabled' do
      AppConfigProperty.create!(key: 'hmis_external_apis/esg_funding_report_enabled', value_input: 'true')
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'globalFeatureFlags', 'esgFundingReportEnabled')).to eq(true)
    end

    it 'is false when the feature flag is set to a truthy value instead of `true`, such as the string "false"' do
      AppConfigProperty.create!(key: 'hmis_external_apis/esg_funding_report_enabled', value_input: '"false"')
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'globalFeatureFlags', 'esgFundingReportEnabled')).to eq(false)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
