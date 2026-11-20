###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe ClientMatchesController, 'scope', type: :request do
  include_context 'visibility test context'

  let!(:user) { create :acl_user }
  let!(:out_of_scope_match) do
    GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: non_window_source_client.id, score: -5.0)
  end
  let!(:in_scope_match) do
    GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: window_source_client_2.id, score: -5.0)
  end

  let!(:out_of_scope_destination_match) do
    GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: non_window_source_client.id, source_client_id: window_source_client_2.id, score: -5.0)
  end

  def create_ongoing_enrollment(project, project_name: project.ProjectName, client: window_destination_client)
    create(
      :grda_warehouse_service_history,
      :service_history_entry,
      client_id: client.id,
      project_id: project.ProjectID,
      organization_id: project.OrganizationID,
      data_source_id: project.data_source_id,
      project_name: project_name,
      first_date_in_program: 1.month.ago.to_date,
      last_date_in_program: nil,
    )
  end

  before do
    window_project.update!(OrganizationID: window_organization.OrganizationID)
    non_window_project.update!(OrganizationID: non_window_organization.OrganizationID)
    Rails.cache.clear
    Collection.maintain_system_groups
    setup_access_control(user, can_edit_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    sign_in user
  end

  it 'lists only the match whose clients are both searchable' do
    get client_matches_path

    ids = Nokogiri::HTML(response.body).css('.client-match').map { |node| node['data-id'].to_i }
    expect(ids).to contain_exactly(in_scope_match.id)
  end

  it 'counts every candidate match in the badge, including matches the user cannot open' do
    get client_matches_path

    badge = Nokogiri::HTML(response.body).at_css('.badge[data-status=candidate]')
    expect(badge.text.strip).to eq('3')
  end

  it 'tells a user with limited search that the counts include matches they cannot open' do
    get client_matches_path

    note = Nokogiri::HTML(response.body).at_css('.client-match-count-note')
    expect(note.text.strip).to eq('Counts include matches for clients you may not have access to.')
  end

  context 'when out-of-scope matches sort ahead of more than a page of in-scope matches' do
    let!(:extra_in_scope_matches) do
      Array.new(26) do
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: window_source_client_2.id, score: -5.0)
      end
    end
    let!(:better_scored_out_of_scope_matches) do
      Array.new(3) do
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: non_window_source_client.id, score: -6.0)
      end
    end
    let(:visible_ids_in_order) { [in_scope_match.id, *extra_in_scope_matches.map(&:id)].sort }

    def listed_ids(page)
      get client_matches_path(page: page)
      Nokogiri::HTML(response.body).css('.client-match').map { |node| node['data-id'].to_i }
    end

    it 'fills each page with in-scope matches in display order' do
      stub_const('ClientMatchesController::SCAN_BATCH_SIZE', 4)

      expect(listed_ids(1)).to eq(visible_ids_in_order.first(25))
      expect(Nokogiri::HTML(response.body).at_css('.pagination a[href*="page=2"]')).not_to be_nil
      expect(listed_ids(2)).to eq(visible_ids_in_order.last(2))
    end

    it 'fills each page with in-scope matches when the scan limit is reached' do
      stub_const('ClientMatchesController::SCAN_BATCH_SIZE', 2)
      stub_const('ClientMatchesController::SCAN_LIMIT', 4)

      expect(listed_ids(1)).to eq(visible_ids_in_order.first(25))
      expect(listed_ids(2)).to eq(visible_ids_in_order.last(2))
    end

    it 'fills the first page when searchable matches that cannot be listed sort first' do
      unlinked_client = create(:grda_warehouse_hud_client, data_source_id: window_visible_data_source.id)
      create(
        :grda_warehouse_hud_enrollment,
        data_source_id: window_visible_data_source.id,
        PersonalID: unlinked_client.PersonalID,
        ProjectID: window_project.ProjectID,
        EntryDate: 1.months.ago.to_date,
      )
      3.times do
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: unlinked_client.id, score: -7.0)
      end

      expect(listed_ids(1)).to eq(visible_ids_in_order.first(25))
      expect(Nokogiri::HTML(response.body).at_css('.pagination a[href*="page=2"]')).not_to be_nil
    end
  end

  it 'refuses to accept a match with an out-of-scope client and leaves it unmerged' do
    patch client_match_path(out_of_scope_match, format: :json), params: { client_match: { status: 'accepted' } }

    expect(response).to have_http_status(:not_found)
    expect(non_window_source_client.reload.destination_client).to eq(non_window_destination_client)
    expect(out_of_scope_match.reload.status).to eq('candidate')
  end

  it 'refuses to accept a match with an out-of-scope destination client and leaves it unmerged' do
    patch client_match_path(out_of_scope_destination_match, format: :json), params: { client_match: { status: 'accepted' } }

    expect(response).to have_http_status(:not_found)
    expect(window_source_client_2.reload.destination_client).to eq(both_destination_client)
    expect(out_of_scope_destination_match.reload.status).to eq('candidate')
  end

  it 'accepts a match whose clients are both searchable' do
    patch client_match_path(in_scope_match, format: :json), params: { client_match: { status: 'accepted' } }

    expect(in_scope_match.reload.status).to eq('accepted')
    expect(window_source_client_2.reload.destination_client).to eq(window_destination_client)
  end

  it 'does not defer an out-of-scope match by destination id' do
    post defer_client_matches_path, params: { destination_client_id: window_source_client.id }, headers: { 'HTTP_REFERER' => client_matches_path }

    expect(out_of_scope_match.reload.defer_count.to_i).to eq(0)
    expect(in_scope_match.reload.defer_count.to_i).to eq(1)
  end

  it 'does not defer an out-of-scope match by match id' do
    post defer_client_match_path(out_of_scope_match), headers: { 'HTTP_REFERER' => client_matches_path }

    expect(out_of_scope_match.reload.defer_count.to_i).to eq(0)
  end

  it 'does not defer a match with an out-of-scope destination client by match id' do
    post defer_client_match_path(out_of_scope_destination_match), headers: { 'HTTP_REFERER' => client_matches_path }

    expect(out_of_scope_destination_match.reload.defer_count.to_i).to eq(0)
  end

  it 'shows ongoing enrollments only for projects the user can view' do
    create_ongoing_enrollment(window_project)
    create_ongoing_enrollment(non_window_project)

    get client_matches_path

    expect(response.body).to include('Visible Project')
    expect(response.body).not_to include('Non-Window Project')
  end

  it 'escapes markup in an ongoing enrollment project name' do
    create_ongoing_enrollment(window_project, project_name: '<b>Shelter</b>')

    get client_matches_path

    expect(response.body).not_to include('<b>Shelter</b>')
    expect(response.body).to include(CGI.escapeHTML('<b>Shelter</b>'))
  end

  it 'escapes markup in an ongoing enrollment project name on the source client side' do
    create_ongoing_enrollment(window_project, project_name: '<i>Outreach</i>', client: both_destination_client)

    get client_matches_path

    expect(response.body).not_to include('<i>Outreach</i>')
    expect(response.body).to include(CGI.escapeHTML('<i>Outreach</i>'))
  end

  it 'shows the obfuscated name for an ongoing enrollment at a confidential project' do
    window_project.update!(confidential: true)
    create_ongoing_enrollment(window_project)

    get client_matches_path

    expect(response.body).to include(GrdaWarehouse::Hud::Project.confidential_project_name)
    expect(response.body).not_to include('Visible Project')
  end

  context 'when the user is granted can_search_all_clients through an access control' do
    let!(:can_search_all_clients) { create :role, can_search_all_clients: true }

    before { setup_access_control(user, can_search_all_clients, Collection.system_collection(:window_data_sources)) }

    it 'still lists only the match inside the granted collection' do
      get client_matches_path

      ids = Nokogiri::HTML(response.body).css('.client-match').map { |node| node['data-id'].to_i }
      expect(ids).to contain_exactly(in_scope_match.id)
    end

    it 'refuses to accept a match with a client outside the granted collection' do
      patch client_match_path(out_of_scope_match, format: :json), params: { client_match: { status: 'accepted' } }

      expect(response).to have_http_status(:not_found)
      expect(out_of_scope_match.reload.status).to eq('candidate')
    end
  end
end

RSpec.describe ClientMatchesController, 'scope for a legacy user', type: :request do
  include_context 'visibility test context'

  let!(:user) { create :user }
  let!(:out_of_scope_match) do
    GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: non_window_source_client.id, score: -5.0)
  end
  let!(:in_scope_match) do
    GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: window_source_client_2.id, score: -5.0)
  end

  before do
    window_project.update!(OrganizationID: window_organization.OrganizationID)
    non_window_project.update!(OrganizationID: non_window_organization.OrganizationID)
    Rails.cache.clear
    user.legacy_roles << can_edit_clients
    user.legacy_roles << can_view_clients
    user.legacy_roles << can_search_own_clients
    window_data_source_viewable.add(user)
    [window_project, non_window_project].each do |project|
      create(
        :grda_warehouse_service_history,
        :service_history_entry,
        client_id: window_destination_client.id,
        project_id: project.ProjectID,
        organization_id: project.OrganizationID,
        data_source_id: project.data_source_id,
        project_name: project.ProjectName,
        first_date_in_program: 1.month.ago.to_date,
        last_date_in_program: nil,
      )
    end
    sign_in user
  end

  it 'lists only the match whose clients are both searchable' do
    get client_matches_path

    ids = Nokogiri::HTML(response.body).css('.client-match').map { |node| node['data-id'].to_i }
    expect(ids).to contain_exactly(in_scope_match.id)
  end

  it 'shows ongoing enrollments only for projects the user can view' do
    get client_matches_path

    expect(response.body).to include('Visible Project')
    expect(response.body).not_to include('Non-Window Project')
  end

  context 'when the user can search all clients' do
    let!(:can_search_all_clients) { create :role, can_search_all_clients: true }

    before { user.legacy_roles << can_search_all_clients }

    it 'lists matches between clients outside any assigned data source' do
      get client_matches_path

      ids = Nokogiri::HTML(response.body).css('.client-match').map { |node| node['data-id'].to_i }
      expect(ids).to contain_exactly(in_scope_match.id, out_of_scope_match.id)
    end

    it 'does not show the note about matches the user cannot open' do
      get client_matches_path

      expect(Nokogiri::HTML(response.body).at_css('.client-match-count-note')).to be_nil
    end

    it 'accepts a match with a client outside any assigned data source' do
      patch client_match_path(out_of_scope_match, format: :json), params: { client_match: { status: 'accepted' } }

      expect(out_of_scope_match.reload.status).to eq('accepted')
    end

    context 'when a match has a client that keeps it off the list' do
      let(:linked_client) do
        create(:warehouse_client, data_source_id: window_visible_data_source.id, destination_id: window_destination_client.id).source
      end
      let(:unlinked_client) { create(:grda_warehouse_hud_client, data_source_id: window_visible_data_source.id) }
      let(:listable_ids) { [in_scope_match.id, out_of_scope_match.id] }

      def badge_count_and_listed_ids(status)
        get client_matches_path(status: status)
        page = Nokogiri::HTML(response.body)
        [
          page.at_css(".badge[data-status=#{status}]").text.strip.to_i,
          page.css('.client-match').map { |node| node['data-id'].to_i },
        ]
      end

      it 'leaves a match with a soft-deleted source client out of the candidate badge and list' do
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: linked_client.id, score: -5.0)
        linked_client.update_columns(DateDeleted: Time.current)

        count, ids = badge_count_and_listed_ids('candidate')

        expect(ids).to match_array(listable_ids)
        expect(count).to eq(2)
      end

      it 'leaves a match whose source client has no destination client out of the candidate badge and list' do
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: window_source_client.id, source_client_id: unlinked_client.id, score: -5.0)

        count, ids = badge_count_and_listed_ids('candidate')

        expect(ids).to match_array(listable_ids)
        expect(count).to eq(2)
      end

      it 'leaves a match whose destination-side client has no destination client out of the candidate badge and list' do
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: unlinked_client.id, source_client_id: window_source_client.id, score: -5.0)

        count, ids = badge_count_and_listed_ids('candidate')

        expect(ids).to match_array(listable_ids)
        expect(count).to eq(2)
      end

      it 'counts only the listed matches in the accepted badge' do
        listed = GrdaWarehouse::ClientMatch.create!(status: 'accepted', destination_client_id: window_source_client.id, source_client_id: linked_client.id, score: -5.0)
        GrdaWarehouse::ClientMatch.create!(status: 'accepted', destination_client_id: window_source_client.id, source_client_id: unlinked_client.id, score: -5.0)

        count, ids = badge_count_and_listed_ids('accepted')

        expect(ids).to contain_exactly(listed.id)
        expect(count).to eq(1)
      end
    end
  end
end
