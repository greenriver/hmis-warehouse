###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard::WhoData, type: :model do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:report) do
    PublicReports::StateDashboard.new(
      user: user,
      filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31'), project_type_numbers: [1] } },
    )
  end
  let(:white_label) { HudHelper.util.races(multi_racial: true)['White'] }
  let(:source_data_source) { create(:data_source_fixed_id) }
  let(:destination_data_source) { create(:grda_warehouse_data_source) }
  let(:organization) { create(:hud_organization, data_source_id: source_data_source.id) }
  let(:project) { create(:hud_project, data_source_id: source_data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1) }

  before do
    travel_to(Date.parse('2026-06-15'))
    setup_access_control(user, role, Collection.system_collection(:data_sources))
    # Census data is loaded from the Census API, so the test supplies the figures.
    white_by_year = { 2024 => 100, 2025 => 600 }
    allow(report.geography).to receive(:population_by_race) do |year:, race_code: 'All'|
      case race_code
      when 'All' then 1_000
      when 'White' then white_by_year.fetch(year)
      else 0
      end
    end
  end

  after { travel_back }

  # Race resolves through a WarehouseClient link to a source client.
  def create_served_client(race_field)
    client = create(:hud_client, data_source_id: destination_data_source.id)
    source = create(:hud_client, data_source_id: source_data_source.id, race_field => 1)
    create(:warehouse_client, destination_id: client.id, source_id: source.id, data_source_id: source_data_source.id)
    enrollment = create(
      :she_entry,
      client: client,
      data_source_id: project.data_source_id,
      project_id: project.project_id,
      organization_id: project.organization_id,
      project_type: 1,
      date: Date.parse('2025-10-15'),
      first_date_in_program: Date.parse('2025-10-15'),
      last_date_in_program: Date.parse('2025-12-31'),
    )
    create(:service_history_service, service_history_enrollment_id: enrollment.id, client_id: client.id, record_type: 'service', date: Date.parse('2025-11-01'), project_type: 1)
  end

  it 'compares the race chart with census figures for the last period year only' do
    race = described_class.new(report).to_h[:race]

    expect(race[:overall][race[:labels].index(white_label)]).to eq(60.0)
    expect(report.geography).not_to have_received(:population_by_race).with(hash_including(year: 2024))
  end

  it 'publishes no census share for any race when the geography has no census population' do
    allow(report.geography).to receive(:population_by_race).and_return(nil)

    race = described_class.new(report).to_h[:race]

    expect(race[:overall]).to eq(Array.new(race[:labels].size))
  end

  it 'counts a client whose only race is Hispanic/Latina/e/o or Middle Eastern/North African under Other or Unknown' do
    stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
    create_served_client(:HispanicLatinaeo)
    create_served_client(:MidEastNAfrican)
    create_served_client(:White)

    race = described_class.new(report).to_h[:race]

    expect(race[:totals].last).to eq(3)
    expect(race[:homeless].last.values_at(race[:labels].index('Other or Unknown'), race[:labels].index(white_label))).to eq([66.7, 33.3])
  end

  describe 'query volume' do
    # [statements run, last-period race chart total]
    def run_who_data
      statements = []
      data = ActiveSupport::Notifications.subscribed(->(*, payload) { statements << payload[:sql] }, 'sql.active_record') do
        described_class.new(PublicReports::StateDashboard.find(report.id)).to_h
      end
      [statements.size, data[:race][:totals].last]
    end

    it 'runs the same number of queries however many clients were served' do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      report.save!
      create_served_client(:White)
      run_who_data # warms per-process caches
      one_client_statements, = run_who_data
      create_served_client(:Asian)
      create_served_client(:BlackAfAmerican)

      expect(run_who_data).to eq([one_client_statements, 3])
    end
  end
end
