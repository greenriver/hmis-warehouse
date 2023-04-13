###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'faker'

RSpec.describe HmisExternalApis::ReferralsController, type: :request do
  describe 'send referral' do

    let(:mci_cred) do
      create(:remote_token_credential, slug: 'mci')
    end

    let(:hud_clients) do
      2.times.map do
        client = create(:hmis_hud_client_complete)
        mci_id = SecureRandom.uuid
        mci_cred.external_ids.create!(source: client, value: mci_id)
        [client, mci_id]
      end
    end

    def referral_params(referral_requests, clients)
      household_members = clients.map do |client, mci_id|
        {
          mci_id: mci_id,
          relationship_to_hoh: 1,
          first_name: client.first_name,
          middle_name: client.middle_name,
          last_name: client.last_name,
          gender: client.gender,
          dob: client.dob,
          ssn: client.ssn,
          # veteran_status: client.veteran_status,
          # discharge_status: 0,
          # race: 0,
          # ethnicity: 0,
          # disabling_condition: 0,
        }
      end
      postings = referral_requests.map do |rr|
        {
          posting_id: 1,
          referral_request_id: rr.identifier,
        }
      end

      {
        referral_id: SecureRandom.uuid,
        referral_date: Date.today,
        service_coordinator: Faker::Name.name,
        household_members: household_members,
        postings: postings,
      }
    end

    let :referral_request  do
      create(:hmis_external_api_referral_request)
    end

    it 'successfully receives a valid referral for known clients' do
      params = referral_params([referral_request], hud_clients)
      post hmis_external_apis_referrals_path, params: params, as: :json
      expect(response.status).to eq 200
      referral = HmisExternalApis::Referral.where(identifier: params.fetch(:referral_id)).first
      expect(referral.referral_postings.map(&:referral_request_id)).to(eq([referral_request.id]))
      expect(referral.referral_clients.size).to(eq(hud_clients.size))

      hud_clients.each do |client, mci_id|
        found = referral.referral_clients.where(hud_client_id: client.id).first!
        expect(mci_cred.external_ids.where(source: found.hud_client, value: mci_id).count).to(eq(1))
      end
    end

  end
end
