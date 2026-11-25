###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaReports::CsgEngage::Report, type: :model do
  describe '.run_if_ready' do
    let!(:agency) { create(:csg_engage_agency) }

    def create_credential(active:)
      MaReports::CsgEngage::Credential.create!(
        username: '',
        active: active,
        endpoint: 'https://www.example.com',
        additional_headers: { 'hour' => Time.current.hour },
        slug: 'csg_engage_endpoint',
        password: 'test',
      )
    end

    before do
      stub_request(:any, /https:\/\/www\.example\.com\/.*/).to_return_json(body: { 'ok' => true })
    end

    it 'creates no reports when the only credential is inactive' do
      create_credential(active: false)

      expect { described_class.run_if_ready }.not_to change(described_class, :count)
    end

    it 'creates one report per agency when the credential is active' do
      create_credential(active: true)

      expect { described_class.run_if_ready }.to change(described_class, :count).by(1)
    end

    it 'creates no reports for an active credential in sandbox mode' do
      create_credential(active: true)

      with_sandbox_mode do
        expect { described_class.run_if_ready }.not_to change(described_class, :count)
      end
    end
  end
end
