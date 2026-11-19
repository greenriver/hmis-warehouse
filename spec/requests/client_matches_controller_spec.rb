###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientMatchesController, type: :request do
  describe '#index' do
    context 'when a matched client name contains markup' do
      let(:destination_ds) { create(:destination_data_source) }
      let(:source_ds) { create(:visible_data_source) }
      let(:user) { create(:user) }

      let(:existing_source) { create(:hud_client, FirstName: 'Existing', LastName: 'Client', data_source_id: source_ds.id) }
      let(:existing_destination) { create(:hud_client, data_source_id: destination_ds.id) }
      let(:proposed_source) { create(:hud_client, FirstName: '<script>alert(1)</script>', LastName: 'Proposed', data_source_id: source_ds.id) }
      let(:proposed_destination) { create(:hud_client, data_source_id: destination_ds.id) }

      before do
        user.legacy_roles << create(:can_edit_clients)
        user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true)
        GrdaWarehouse::WarehouseClient.create!(destination_id: existing_destination.id, source_id: existing_source.id, id_in_source: existing_source.PersonalID)
        GrdaWarehouse::WarehouseClient.create!(destination_id: proposed_destination.id, source_id: proposed_source.id, id_in_source: proposed_source.PersonalID)
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: existing_source.id, source_client_id: proposed_source.id, score: -5.0)
        sign_in user
      end

      it 'escapes a client full name embedded in the accept-tooltip markup, rather than injecting it verbatim' do
        get client_matches_path

        expect(response.body).not_to include('<script>alert(1)</script>')
        expect(response.body).to include(CGI.escapeHTML('<script>alert(1)</script>'))
      end

      it 'renders the accept-tooltip as plain text rather than opting into HTML rendering' do
        get client_matches_path

        accept_link = Nokogiri::HTML(response.body).at_css('a[data-bs-toggle="tooltip"][data-bs-title]')
        expect(accept_link['data-bs-html']).to be_nil
      end

      it 'renders the accept-tooltip without error when a matched client has no name on file' do
        blank_name_source = create(:hud_client, data_source_id: source_ds.id)
        blank_name_destination = create(:hud_client, data_source_id: destination_ds.id)
        GrdaWarehouse::WarehouseClient.create!(destination_id: blank_name_destination.id, source_id: blank_name_source.id, id_in_source: blank_name_source.PersonalID)
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: blank_name_source.id, source_client_id: proposed_source.id, score: -5.0)

        get client_matches_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("into existing:\n #{blank_name_source.uuid}")
      end
    end

    context 'when a matched client is restricted' do
      let!(:user) { create(:acl_user) }
      let!(:role) { create(:role, can_edit_clients: true, can_search_own_clients: true, can_view_client_name: true, can_view_full_ssn: true, can_view_full_dob: true) }
      let!(:collection) { Collection.system_collection(:data_sources) }

      let!(:hmis_ds) { create(:hmis_primary_data_source, authoritative: true) }
      let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
      let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client', ssn: '111223333', dob: '1980-01-01') }
      let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
      let!(:candidate_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Candidate', LastName: 'Client') }
      let!(:candidate_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Candidate', last_name: 'Client', ssn: '444556666', dob: '1985-06-15') }
      let!(:match) do
        GrdaWarehouse::ClientMatch.create!(
          destination_client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id),
          source_client: GrdaWarehouse::Hud::Client.find(candidate_source_client.id),
          status: 'candidate',
          # `_client_match.haml` renders `match.score.round(2).abs` unconditionally.
          score: -1.0,
        )
      end

      before do
        Collection.maintain_system_groups
        setup_access_control(user, role, collection)
        GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
        GrdaWarehouse::WarehouseClient.create!(destination_id: candidate_destination_client.id, source_id: candidate_source_client.id, data_source_id: hmis_ds.id, id_in_source: candidate_source_client.id.to_s)
        restricted_source_client.mark_as_restricted!(user: hmis_user)
        sign_in user
      end

      it 'redacts the restricted destination client name in the match heading' do
        get client_matches_path

        expect(response.body).not_to include('Restricted Client')
        expect(response.body).to include('Name Redacted')
      end

      it 'redacts the restricted client name, SSN, and DOB in the match card' do
        get client_matches_path

        expect(response.body).to include('Candidate Client')
        expect(response.body).not_to include('Restricted Client')
        expect(response.body).not_to include('111-22-3333')
        expect(response.body).not_to include('Jan  1, 1980')
      end

      it 'shows the unrestricted candidate client name, SSN, and DOB in the match card' do
        get client_matches_path

        expect(response.body).to include('Candidate Client')
        expect(response.body).to include('444-55-6666')
        expect(response.body).to include('Jun 15, 1985')
      end
    end
  end

  describe '#index tabs' do
    let(:user) { create(:user) }

    before do
      Rails.cache.clear
      user.legacy_roles << create(:can_edit_clients)
      user.legacy_roles << create(:role, can_search_all_clients: true)
      sign_in user
    end

    it 'marks the candidate tab as viewed by default' do
      get client_matches_path

      expect(Nokogiri::HTML(response.body).at_css('.client-match-tabs')['data-status']).to eq('candidate')
    end

    it 'marks the viewed status on the tabs' do
      get client_matches_path(status: 'rejected')

      expect(Nokogiri::HTML(response.body).at_css('.client-match-tabs')['data-status']).to eq('rejected')
    end

    it 'renders a hidden badge with a zero count for each status without matches' do
      get client_matches_path

      badges = Nokogiri::HTML(response.body).css('.client-match-tabs .badge')
      expect(badges.map { |b| [b['data-status'], b.text, b['class'].split.include?('d-none')] }).
        to contain_exactly(['candidate', '0', true], ['accepted', '0', true], ['rejected', '0', true])
    end
  end

  describe '#update' do
    let(:source_ds) { create(:visible_data_source) }
    let(:user) { create(:user) }
    let(:existing_source) { create(:hud_client, FirstName: 'Existing', LastName: 'Client', SSN: '123456789', data_source_id: source_ds.id) }
    let(:proposed_source) { create(:hud_client, FirstName: 'Proposed', LastName: 'Client', SSN: '987654321', data_source_id: source_ds.id) }
    let!(:match) do
      GrdaWarehouse::ClientMatch.create!(
        status: 'candidate',
        destination_client_id: existing_source.id,
        source_client_id: proposed_source.id,
        score: -5.0,
        score_details: {
          destination_client: existing_source.attributes.slice('id', 'FirstName', 'LastName', 'SSN'),
          source_client: proposed_source.attributes.slice('id', 'FirstName', 'LastName', 'SSN'),
        },
      )
    end

    before do
      Rails.cache.clear
      user.legacy_roles << create(:can_edit_clients)
      user.legacy_roles << create(:role, can_search_all_clients: true)
      sign_in user
    end

    it 'returns only the match id and status, without the stored client details' do
      patch client_match_path(match, format: :json), params: { client_match: { status: 'rejected' } }

      expect(response.parsed_body).to eq('id' => match.id, 'status' => 'rejected')
      expect(response.body).not_to include('987654321')
    end

    it 'moves a rejected match back to candidate' do
      match.update!(status: 'rejected')

      patch client_match_path(match, format: :json), params: { client_match: { status: 'candidate' } }

      expect(response.parsed_body).to eq('id' => match.id, 'status' => 'candidate')
      expect(match.reload.status).to eq('candidate')
    end

    context 'when another user saves the match first' do
      before do
        bumped = false
        allow_any_instance_of(GrdaWarehouse::ClientMatch).to receive(:update).and_wrap_original do |original, *args, **kwargs|
          unless bumped
            bumped = true
            GrdaWarehouse::ClientMatch.update_counters(match.id, lock_version: 1)
          end
          original.call(*args, **kwargs)
        end
      end

      it 'returns conflict and keeps the rejected status on undo' do
        match.update!(status: 'rejected')

        patch client_match_path(match, format: :json), params: { client_match: { status: 'candidate' } }

        expect(response).to have_http_status(:conflict)
        expect(match.reload.status).to eq('rejected')
      end

      it 'returns conflict, keeps the candidate status, and merges nothing on accept' do
        expect_any_instance_of(GrdaWarehouse::Hud::Client).not_to receive(:merge_from)

        patch client_match_path(match, format: :json), params: { client_match: { status: 'accepted' } }

        expect(response).to have_http_status(:conflict)
        expect(match.reload.status).to eq('candidate')
      end

      it 'returns conflict and keeps the candidate status on reject' do
        patch client_match_path(match, format: :json), params: { client_match: { status: 'rejected' } }

        expect(response).to have_http_status(:conflict)
        expect(match.reload.status).to eq('candidate')
      end
    end

    it 'saves the status and redirects to the match list for an HTML request without a referrer' do
      patch client_match_path(match), params: { client_match: { status: 'rejected' } }

      expect(response).to redirect_to(client_matches_path)
      expect(match.reload.status).to eq('rejected')
    end

    it 'leaves an accepted match accepted when asked for candidate' do
      match.update!(status: 'accepted')

      patch client_match_path(match, format: :json), params: { client_match: { status: 'candidate' } }

      expect(response.parsed_body).to eq('id' => match.id, 'status' => 'accepted')
      expect(match.reload.status).to eq('accepted')
    end
  end

  describe '#index badge for a count of a thousand' do
    let(:user) { create(:user) }

    before do
      Rails.cache.clear
      user.legacy_roles << create(:can_edit_clients)
      user.legacy_roles << create(:role, can_search_all_clients: true, can_view_clients: true, can_view_client_name: true)
      destination, source = Array.new(2) { create(:warehouse_client).source }
      GrdaWarehouse::ClientMatch.insert_all(
        Array.new(1_000) { { status: 'candidate', destination_client_id: destination.id, source_client_id: source.id, score: -5.0 } },
      )
      sign_in user
    end

    it 'shows the count with a thousands separator and keeps the plain number in data-count' do
      get client_matches_path

      badge = Nokogiri::HTML(response.body).at_css('.badge[data-status=candidate]')
      expect(badge.text.strip).to eq('1,000')
      expect(badge['data-count']).to eq('1000')
    end
  end

  describe '#index candidate order' do
    let(:user) { create(:user) }

    before do
      Rails.cache.clear
      user.legacy_roles << create(:can_edit_clients)
      user.legacy_roles << create(:role, can_search_all_clients: true, can_view_clients: true, can_view_client_name: true)
      sign_in user
    end

    def create_match(score:, defer_count: nil)
      destination, source = Array.new(2) { create(:warehouse_client).source }
      GrdaWarehouse::ClientMatch.create!(
        status: 'candidate',
        destination_client_id: destination.id,
        source_client_id: source.id,
        score: score,
        defer_count: defer_count,
      )
    end

    def listed_ids
      get client_matches_path
      Nokogiri::HTML(response.body).css('.client-match').map { |node| node['data-id'].to_i }
    end

    context 'with three matches that were never deferred' do
      let!(:best) { create_match(score: -9.0) }
      let!(:middle) { create_match(score: -8.0) }
      let!(:worst) { create_match(score: -7.0) }

      it 'lists them by score' do
        expect(listed_ids).to eq([best.id, middle.id, worst.id])
      end

      it 'moves a deferred match behind the matches that were never deferred' do
        post defer_client_match_path(best)

        expect(listed_ids).to eq([middle.id, worst.id, best.id])
      end

      it 'lists deferred matches with the same defer count by score' do
        post defer_client_match_path(middle)
        post defer_client_match_path(best)

        expect(listed_ids).to eq([worst.id, best.id, middle.id])
      end

      it 'lists a match deferred twice behind a match deferred once' do
        post defer_client_match_path(middle)
        2.times { post defer_client_match_path(best) }

        expect(listed_ids).to eq([worst.id, middle.id, best.id])
      end
    end

    it 'lists matches with a zero or missing defer count ahead of a deferred match' do
      zero = create_match(score: -7.0, defer_count: 0)
      never = create_match(score: -8.0)
      deferred = create_match(score: -9.0)

      post defer_client_match_path(deferred)

      ids = listed_ids
      expect(ids.first(2)).to contain_exactly(zero.id, never.id)
      expect(ids.last).to eq(deferred.id)
    end
  end

  describe '#defer without a referrer' do
    let(:user) { create(:user) }
    let(:source_ds) { create(:visible_data_source) }
    let!(:match) do
      a = create(:hud_client, data_source_id: source_ds.id)
      b = create(:hud_client, data_source_id: source_ds.id)
      GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: a.id, source_client_id: b.id, score: -5.0)
    end

    before do
      Rails.cache.clear
      user.legacy_roles << create(:can_edit_clients)
      user.legacy_roles << create(:role, can_search_all_clients: true)
      sign_in user
    end

    it 'redirects to the match list' do
      post defer_client_match_path(match)

      expect(response).to redirect_to(client_matches_path)
      expect(match.reload.defer_count).to eq(1)
    end
  end
end
