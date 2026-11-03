###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaYyaReport::UniverseCalculator, 'against enrollment records' do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }
  let!(:collection) { create(:collection) }
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, organization: organization, data_source: data_source, ProjectType: 1) }

  let(:report) { create(:ma_yya_report) }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: Date.new(2024, 1, 1),
      end: Date.new(2024, 12, 31),
      enforce_one_year_range: false,
    )
  end
  let(:entry_date) { Date.new(2024, 3, 1) }

  before do
    Rails.cache.clear
    Collection.maintain_system_groups
    collection.set_viewables({ projects: [project.id] })
    setup_access_control(user, role, collection)
  end

  # A youth with a source client, an HMIS enrollment in `project`, and the matching service history entry
  def create_youth
    source_client = create(:hud_client, data_source: data_source, DOB: entry_date - 20.years)
    destination_client = create(:grda_warehouse_hud_client, DOB: entry_date - 20.years)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_client.id, data_source_id: data_source.id, id_in_source: source_client.PersonalID)
    enrollment = create(:hud_enrollment, PersonalID: source_client.PersonalID, ProjectID: project.ProjectID, data_source: data_source, EntryDate: entry_date, HouseholdID: "hh-#{source_client.PersonalID}")
    create(:hud_current_living_situation, EnrollmentID: enrollment.EnrollmentID, PersonalID: source_client.PersonalID, data_source: data_source, InformationDate: entry_date, CurrentLivingSituation: 116)
    create(:she_entry, client: destination_client, data_source: data_source, project: project, enrollment_group_id: enrollment.EnrollmentID, household_id: enrollment.HouseholdID, project_type: 1, head_of_household: true, first_date_in_program: entry_date, last_date_in_program: nil)
    [destination_client, enrollment]
  end

  def add_disability(enrollment, information_date:, response:)
    create(:hud_disability, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID, data_source: data_source, DisabilityType: 9, DisabilityResponse: response, IndefiniteAndImpairs: 1, InformationDate: information_date)
  end

  def calculated_clients
    results = []
    described_class.new(filter, report).calculate { |clients| results.concat(clients.values) }
    results
  end

  def query_count
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:cached] || payload[:name].in?(['SCHEMA', 'TRANSACTION']) }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { yield }
    count
  end

  it 'issues the same number of queries regardless of how many clients are in a batch' do
    _, enrollment = create_youth
    add_disability(enrollment, information_date: entry_date, response: 1)
    calculated_clients # warm one-time lookups

    single_client_queries = query_count { calculated_clients }
    2.times do
      _, enrollment = create_youth
      add_disability(enrollment, information_date: entry_date, response: 1)
    end
    three_client_queries = query_count { calculated_clients }

    expect(calculated_clients.size).to eq(3)
    expect(three_client_queries).to eq(single_client_queries)
  end

  describe 'disability flags' do
    it 'uses the most recent response before the report end' do
      yes_then_no_client, yes_then_no = create_youth
      add_disability(yes_then_no, information_date: entry_date, response: 1)
      add_disability(yes_then_no, information_date: entry_date + 1.month, response: 0)

      no_then_yes_client, no_then_yes = create_youth
      add_disability(no_then_yes, information_date: entry_date, response: 0)
      add_disability(no_then_yes, information_date: entry_date + 1.month, response: 1)

      flags = calculated_clients.to_h { |client| [client.client_id, client.mental_health_disorder] }

      expect(flags).to eq(yes_then_no_client.id => false, no_then_yes_client.id => true)
    end
  end
end
