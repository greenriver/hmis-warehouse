###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

# CAUTION: This is not part of the normal test suite. It runs against a live remote endpoint
# We need many secrets to test this. Essentially, this runs locally or on staging
RSpec.describe 'Data Warehouse API', type: :model do
  if ENV['OAUTH_CREDENTIAL_TEST'] == 'true'
    let(:ssk) { ENV.fetch('AC_DW_SSK') }
    let(:client_id) { ENV.fetch('AC_DW_CLIENT_ID') }
    let(:base_url) { ENV.fetch('AC_DW_BASE_URL') }
    let(:client_secret) { ENV.fetch('AC_DW_CLIENT_SECRET') }
    let(:token_url) { ENV.fetch('AC_DW_TOKEN_URL') }
    let(:ocp_apim_subscription_key) { ENV.fetch('AC_DW_OCP_APIM_SUBSCRIPTION_KEY') }
    let(:api_key) { ENV.fetch('AC_DW_API_KEY') }
    let(:mci_unique_id) { ENV.fetch('AC_DW_MCI_UNIQUE_ID') }

    let(:subject) { HmisExternalApis::AcHmis::DataWarehouseApi.new }

    before do
      user_pass_base_64 = Base64.encode64("#{client_id}:#{client_secret}")

      ::GrdaWarehouse::RemoteCredentials::Oauth.create!(
        client_id: client_id,
        client_secret: client_secret,
        token_url: token_url,
        additional_headers: {
          'X-DwApi-Key' => api_key,
          'Ocp-Apim-Subscription-Key' => ocp_apim_subscription_key,
          'Authorization' => "Basic #{user_pass_base_64}",
        },
        base_url: base_url,
        oauth_scope: 'API_TEST',
        slug: HmisExternalApis::AcHmis::DataWarehouseApi::SYSTEM_ID,
        active: true,
        other_values: {
          src_sys_key: ssk,
        },
      )
    end

    it 'supports getting golden client by MCI unique ID' do
      result = subject.golden_client_by_mci_unique_id(mci_unique_id)

      expect(result.http_status).to eq(200)

      found_mci_unique_id = result.parsed_body['data'].first['mciUniqId'].to_s

      expect(found_mci_unique_id).to eq(mci_unique_id)
    end

    it 'supports getting changes' do
      result = subject.first_page_of_changes

      expect(result.http_status).to eq(200)

      expect(result.parsed_body.keys).to include('paging')
      expect(result.parsed_body.keys).to include('message')
      expect(result.parsed_body.keys).to include('data')
    end

    it 'supports pagination of changes' do
      did_run = false
      records_handled = 0

      subject.each_change do |_record, _record_count, page_count|
        did_run = true
        records_handled += 1
        break if page_count == 3
      end

      expect(records_handled).to be > 400
      expect(did_run).to eq(true)
    end

    it 'handles errors' do
      expect { subject.golden_client_by_mci_unique_id('12345/not-a-thing/whoops') }.to raise_error(HmisErrors::ApiError)
    end
  end
end
