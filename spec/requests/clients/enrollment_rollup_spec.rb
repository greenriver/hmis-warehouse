###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/enrollment_rollup_context'
require 'nokogiri'

RSpec.describe 'Client dashboard enrollment rollups', type: :request do
  include_context 'enrollment rollup context'

  # Any affiliation makes the tooltip index non-empty, so the view has to load it.
  let!(:affiliation) do
    create(
      :hud_affiliation,
      data_source_id: data_source.id,
      ProjectID: shelter_a.ProjectID,
      ResProjectID: housing.ProjectID,
    )
  end

  before { sign_in user }

  def fetch_rollup(client, partial: :residential_enrollments)
    get rollup_client_path(client, partial: partial), xhr: true
    expect(response).to have_http_status(:ok)
    Nokogiri::HTML(response.body)
  end

  describe 'residential enrollments table' do
    it 'renders one row per enrollment with project names and totals' do
      doc = fetch_rollup(destination_client)
      rows = doc.css('tbody tr')
      expect(rows.size).to eq(3)
      expect(rows.map { |r| r.css('td')[1].text.strip }).to eq(['Housing < Test Org', 'Shelter B < Test Org', 'Shelter A < Test Org'])
      totals = doc.css('thead tr').last.css('th.num-cell').map { |th| th.text.strip.squish }
      expect(totals).to eq(['41', '18 / 37', '1'])
    end

    it 'renders household member names for a user who may view client names' do
      doc = fetch_rollup(destination_client)
      member_cell = doc.css('tbody tr').last.css('.client__enrollment--household')
      expect(member_cell.text).to include('Mia Member')
      expect(member_cell.css('a').first['href']).to eq(client_path(household_member_destination.id))
    end

    it 'redacts household member names for a user who may not view client names' do
      name_restricted_role = create :role, name: 'name restricted', can_view_clients: true, can_view_limited_client_dashboard: true
      sign_out user
      sign_in create_user_with_role(name_restricted_role)

      doc = fetch_rollup(destination_client)
      member_cell = doc.css('tbody tr').last.css('.client__enrollment--household')
      expect(member_cell.text).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      expect(member_cell.text).not_to include('Mia')
      expect(member_cell.text).not_to include('Member')
    end

    it 'renders HMIS source links and the source column when the user can see source data' do
      doc = fetch_rollup(destination_client)
      expect(doc.css('a.btn-hmis').map(&:text)).to include('HMIS Enrollment', 'HMIS Exit')
      expect(doc.css('thead tr').first.css('th').size).to eq(10)
    end

    it 'omits HMIS source links and the source column when the user cannot see source data' do
      sign_out user
      sign_in create_user_with_role(viewer_role)

      doc = fetch_rollup(destination_client)
      expect(doc.css('a.btn-hmis')).to be_empty
      expect(doc.css('thead tr').first.css('th').size).to eq(9)
    end

    it 'marks the first shelter stay as a new episode' do
      doc = fetch_rollup(destination_client)
      expect(doc.css('tbody tr.enrollment__new-episode').size).to eq(1)
    end
  end

  describe 'other enrollments table' do
    it 'renders an empty state when the client has no non-residential enrollments' do
      doc = fetch_rollup(destination_client, partial: :other_enrollments)
      expect(doc.text).to include('No enrollments on file')
    end
  end

  describe 'duplicated enrollments' do
    let!(:shelter_a_duplicate) do
      create_enrollment(source_client, shelter_a, entry: '2021-01-01', exit_date: '2021-01-11', HouseholdID: 'hh-a-dup', RelationshipToHoH: 1)
    end

    before { rebuild_service_history! }

    it 'marks one of two same-day rows as a new episode, and it is the lower row' do
      doc = fetch_rollup(destination_client)
      rows = doc.css('tbody tr')
      expect(rows.size).to eq(4)
      expect(doc.css('tbody tr.enrollment__new-episode').size).to eq(1)
      expect(rows.last['class']).to include('enrollment__new-episode')
      expect(rows[-2]['class'].to_s).not_to include('enrollment__new-episode')
    end
  end

  describe 'query scaling' do
    # GrdaWarehouse::Hud::Client#pii_provider -> User#policy_for is an ACL/PII policy
    # check that can't be shared across different people, so it costs a small constant
    # number of queries per distinct household member shown, regardless of how many
    # rows they appear on.
    let(:per_person_query_cost) { 5 }

    it 'renders eight enrollments with the same number of queries as two, aside from per-person PII policy checks' do
      few = build_client_with_es_enrollments(count: 2)
      many = build_client_with_es_enrollments(count: 8)
      fetch_rollup(few)

      few_queries = count_database_queries { fetch_rollup(few) }
      many_queries = count_database_queries { fetch_rollup(many) }

      additional_people = 8 - 2
      expect(fetch_rollup(many).css('tbody tr').size).to eq(8)
      expect(many_queries - few_queries).to be <= additional_people * per_person_query_cost
    end

    it 'does not add per-appearance cost when the same household member appears on every row' do
      few = build_client_with_es_enrollments(count: 2, shared_household_member: true)
      many = build_client_with_es_enrollments(count: 8, shared_household_member: true)
      fetch_rollup(few)

      few_queries = count_database_queries { fetch_rollup(few) }
      many_queries = count_database_queries { fetch_rollup(many) }

      expect(fetch_rollup(many).css('tbody tr').size).to eq(8)
      expect(many_queries).to eq(few_queries)
    end
  end
end
