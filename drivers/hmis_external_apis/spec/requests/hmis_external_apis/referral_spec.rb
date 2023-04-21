###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'faker'

RSpec.describe HmisExternalApis::ReferralsController, type: :request do
  describe 'send referral' do
    include_context 'hmis base setup'

    def random_id
      @start ||= rand(0...1_000).round
      @start += 1
      @start.to_s
    end

    let(:mci_cred) do
      create(:remote_oauth_credential, slug: 'mci')
    end

    let(:clients) do
      2.times.map do
        client = create(:hmis_hud_client_complete)
        mci_id = random_id
        mci_cred.external_ids.create!(source: client, value: mci_id)
        [client, mci_id]
      end
    end

    def household_member_params(clients)
      clients.map do |client, mci_id|
        {
          mci_id: mci_id,
          relationship_to_hoh: 99,
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
        }.compact
      end
    end

    def referral_params(clients)
      {
        referral_id: random_id,
        referral_date: Date.today,
        service_coordinator: Faker::Name.name,
        posting_id: random_id,
        program_id: project_mper_id, # project == program
        household_members: household_member_params(clients),
      }
    end

    let :referral_request do
      create(
        :hmis_external_api_referral_request,
        project: project,
        requested_by: hmis_user, # defined in 'hmis_base_setup' context
      )
    end

    let :project_mper_id do
      random_id
    end

    let :mper_cred do
      create(:remote_oauth_credential, slug: 'mper')
    end

    let :project do
      create(:hmis_hud_project)
    end

    before(:each) do
      mper_cred
        .external_ids.where(source: project)
        .create!(value: project_mper_id)
    end

    it 'receives referral for referral request' do
      params = referral_params(clients)
        .merge({ referral_request_id: referral_request.identifier })
      post hmis_external_apis_referrals_path, params: params, as: :json
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['errors']).to be_nil
      expect(response.status).to eq 200

      referral = HmisExternalApis::Referral.where(identifier: params.fetch(:referral_id)).first
      expect(referral.postings.map(&:referral_request_id)).to(eq([referral_request.id]))
      expect(referral.postings.map(&:project_id)).to(eq([referral_request.project_id]))
      expect(referral.household_members.size).to(eq(clients.size))

      clients.each do |client, mci_id|
        found = referral.household_members.where(client_id: client.id).first!
        expect(mci_cred.external_ids.where(source: found.client, value: mci_id).count).to(eq(1))
      end
    end

    it 'receives referral assignment' do
      params = referral_params(clients)
      post hmis_external_apis_referrals_path, params: params, as: :json
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['errors']).to be_nil
      expect(response.status).to eq 200

      referral = HmisExternalApis::Referral.where(identifier: params.fetch(:referral_id)).first
      expect(referral.postings.map(&:project_id)).to(eq([project.id]))
      expect(referral.household_members.size).to(eq(clients.size))
    end
  end
end
