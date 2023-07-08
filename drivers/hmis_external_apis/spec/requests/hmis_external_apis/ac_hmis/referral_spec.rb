###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'faker'

RSpec.describe HmisExternalApis::AcHmis::ReferralsController, type: :request do
  describe 'send referral' do
    include_context 'hmis base setup'

    def random_id
      @start ||= rand(0...1_000).round
      @start += 1
      @start.to_s
    end

    let!(:mci) do
      create(:ac_hmis_mci_credential)
      ::HmisExternalApis::AcHmis::Mci.new
    end

    let!(:mper) do
      create(:ac_hmis_mper_credential)
      ::HmisExternalApis::AcHmis::Mper.new
    end

    let(:unit_type_id) do
      record = mper.create_external_id(source: create(:hmis_unit_type), value: random_id)
      record.value
    end

    def household_member_params(household)
      household.map do |record|
        record => { client:, mci_id:, relationship_to_hoh: }
        {
          mci_id: mci_id,
          # make the first client the hoh
          relationship_to_hoh: ::HudUtility.hud_list_map_as_enumerable(:relationship_to_ho_h_map).fetch(relationship_to_hoh),
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

    def referral_params(household)
      {
        referral_id: random_id,
        referral_date: Date.today,
        service_coordinator: Faker::Name.name,
        posting_id: random_id,
        program_id: project_mper_id, # project == program
        household_members: household_member_params(household),
        unit_type_id: unit_type_id,
        score: 8,
        needs_wheelchair_accessible_unit: false,
        referral_notes: 'referral note',
        resource_coordinator_notes: 'resource coord note',
        chronic: false,
        addresses: [
          {
            line1: '123 Main st',
            line2: '',
            city: 'Brattleboro',
            state: 'VT',
            county: '',
            zip: '05301',
            use: 'work',
          },
        ],
        phone_numbers: [
          number: '1234567890',
          notes: 'phone note',
          type: 'mobile',
        ],
        email_address: ['test@example.com'],
      }
    end

    def check_response_okay
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['errors']).to be_nil
      expect(response.status).to eq 200
    end

    let :referral_request do
      create(
        :hmis_external_api_ac_hmis_referral_request,
        project: project,
        requested_by: hmis_user, # defined in 'hmis_base_setup' context
      )
    end

    let :project_mper_id do
      project.ProjectID
    end

    let :project do
      create(:hmis_hud_project, data_source: ds1)
    end

    let(:headers) do
      conf = create(:inbound_api_configuration, internal_system: create(:internal_system, :referrals))
      { 'Authorization' => "Bearer #{conf.plain_text_api_key}" }
    end

    context 'with existing household' do
      let(:household) do
        2.times.map do |idx|
          client = create(:hmis_hud_client_complete, data_source: ds1)
          mci_id = random_id
          mci.create_external_id(source: client, value: mci_id)
          {
            client: client,
            mci_id: mci_id,
            relationship_to_hoh: idx.zero? ? 'self_head_of_household' : 'other_relative',
          }
        end
      end

      it 'receives referral for referral request' do
        params = referral_params(household)
          .merge({ referral_request_id: referral_request.identifier })
        post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
        check_response_okay

        referral = HmisExternalApis::AcHmis::Referral.where(identifier: params.fetch(:referral_id)).first
        expect(referral.postings.map(&:referral_request_id)).to(eq([referral_request.id]))
        expect(referral.postings.map(&:project_id)).to(eq([referral_request.project_id]))
        expect(referral.household_members.size).to(eq(household.size))
      end

      it 'receives referral assignment' do
        params = referral_params(household)
        post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
        check_response_okay

        referral = HmisExternalApis::AcHmis::Referral.where(identifier: params.fetch(:referral_id)).first
        expect(referral.postings.map(&:project_id)).to(eq([project.id]))
        expect(referral.household_members.size).to(eq(household.size))
      end

      it 'errors if multiple household members are hoh' do
        household[0][:relationship_to_hoh] = 'self_head_of_household'
        household[1][:relationship_to_hoh] = 'self_head_of_household'

        params = referral_params(household)
        post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
        parsed_body = JSON.parse(response.body)
        expect(parsed_body['errors']).to eq(['Household must have exactly one HoH'])
      end

      it 'errors if no household members are hoh' do
        household[0][:relationship_to_hoh] = 'other_relative'
        household[1][:relationship_to_hoh] = 'other_relative'

        params = referral_params(household)
        post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
        parsed_body = JSON.parse(response.body)
        expect(parsed_body['errors']).to eq(['Household must have exactly one HoH'])
      end

      context 'with existing closed referral' do
        let(:referral) do
          current_posting = create(:hmis_external_api_ac_hmis_referral_posting)
          current_posting.closed_status!
          referral = current_posting.referral
          household.each do |record|
            referral.household_members.create!(**record)
          end
          referral
        end

        it 'receives new postings' do
          params = referral_params(household)
            .merge({ referral_id: referral.identifier })
          post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
          check_response_okay
          expect(referral.postings.size).to(eq(2))
          expect(referral.household_members.size).to(eq(household.size))
        end

        it 'updates relationship to hoh' do
          # swap hoh
          household[0][:relationship_to_hoh] = 'other_relative'
          household[1][:relationship_to_hoh] = 'self_head_of_household'

          params = referral_params(household)
            .merge({ referral_id: referral.identifier })
          post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
          check_response_okay
          referral.reload

          hoh = referral.household_members.where(relationship_to_hoh: 'other_relative').first!
          expect(hoh.client).to eq(household[0][:client])

          non_hoh = referral.household_members.where(relationship_to_hoh: 'self_head_of_household').first!
          expect(non_hoh.client).to eq(household[1][:client])
        end

        it 'removes stale household members' do
          reduced_household = household.take(1)
          params = referral_params(reduced_household)
            .merge({ referral_id: referral.identifier })
          post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
          check_response_okay
          expect(referral.household_members.to_a.map(&:client)).to(eq([reduced_household.first[:client]]))
        end
      end
    end

    it 'receives referral for new clients' do
      mci_id = random_id
      household = [
        {
          client: build(:hmis_hud_client_complete),
          mci_id: mci_id,
          relationship_to_hoh: 'self_head_of_household',
        },
      ]
      params = referral_params(household)
      post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
      check_response_okay

      referral = HmisExternalApis::AcHmis::Referral.where(identifier: params.fetch(:referral_id)).first
      expect(referral.postings.map(&:project_id)).to(eq([project.id]))
      expect(referral.household_members.size).to(eq(household.size))
      client = mci.find_client_by_mci(mci_id)
      expect(client).to(be_present)
      expect(client.addresses.size).to(eq(1))
      expect(client.contact_points.group_by(&:system)['phone'].size).to(eq(1))
      expect(client.contact_points.group_by(&:system)['email'].size).to(eq(1))
    end

    it 'updates client attributes' do
      mci_id = random_id
      client = create(:hmis_hud_client_complete, data_source: ds1)
      mci.create_external_id(source: client, value: mci_id)

      household = [
        {
          client: client,
          mci_id: mci_id,
          relationship_to_hoh: 'self_head_of_household',
        },
      ]

      params = referral_params(household)
      expected = {
        first_name: 'Thisisanewfirstnamefortesting',
        middle_name: 'Thisisanewmiddlenamefortesting',
        last_name: 'Thisisanewlastnamefortesting',
        ssn: '552563593',
        dob: '1990-02-14',
      }
      params[:household_members][0].merge!(expected)
      post hmis_external_apis_referrals_path, params: params, headers: headers, as: :json
      check_response_okay

      referral = HmisExternalApis::AcHmis::Referral.where(identifier: params.fetch(:referral_id)).first
      expect(referral.postings.map(&:project_id)).to(eq([project.id]))
      expect(referral.household_members.size).to(eq(1))
      client.reload
      expected.each_pair do |key, value|
        case key
        when :dob
          expect(client.send(key).strftime('%Y-%m-%d')).to(eq(value))
        else
          expect(client.send(key)).to(eq(value))
        end
      end
      expect(client.names.size).to(eq(2))
      expect(client.addresses.size).to(eq(1))
      expect(client.contact_points.group_by(&:system)['phone'].size).to(eq(1))
      expect(client.contact_points.group_by(&:system)['email'].size).to(eq(1))
    end
  end
end
