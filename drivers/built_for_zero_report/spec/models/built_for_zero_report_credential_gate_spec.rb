###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuiltForZeroReport, type: :model do
  describe '.submit_via_api!' do
    let(:user) { create(:user) }
    let(:range) { [Date.current.beginning_of_month, Date.current] }

    def create_credential(active:)
      BuiltForZeroReport::Credential.create!(
        active: active,
        username: 'user',
        password: 'secret',
        endpoint: 'https://bfz.example.com',
        path: 'api-key',
        bucket: 'community-1',
        slug: 'bfz',
      )
    end

    before do
      stub_request(:any, /bfz\.example\.com/).to_return_json(body: { 'access_token' => 'token', 'expires_in' => 3600 })
    end

    it 'raises and makes no request when the only credential is inactive' do
      create_credential(active: false)

      expect { described_class.submit_via_api!(*range, user: user) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(WebMock).not_to have_requested(:any, /bfz\.example\.com/)
    end

    it 'raises and makes no request for an active credential in sandbox mode' do
      create_credential(active: true)

      with_sandbox_mode do
        expect { described_class.submit_via_api!(*range, user: user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
      expect(WebMock).not_to have_requested(:any, /bfz\.example\.com/)
    end

    it 'contacts the API when the credential is active' do
      create_credential(active: true)
      stub_request(:get, /bfz\.example\.com\/rest\/v1\/subpopulations/).to_return_json(body: [])
      stub_request(:post, /bfz\.example\.com\/rest\/v1\/community_reported_population/).to_return(status: 201)

      described_class.submit_via_api!(*range, user: user)

      expect(WebMock).to have_requested(:get, /bfz\.example\.com\/rest\/v1\/subpopulations/)
    end
  end
end
