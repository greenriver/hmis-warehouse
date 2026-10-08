###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard::MapData, type: :model do
  subject(:map_data) { described_class.new(report) }

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:settings) { PublicReports::Setting.first_or_create }
  let(:report) do
    PublicReports::StateDashboard.new(
      user: user,
      filter: { filters: { start: Date.parse('2025-01-01'), end: Date.parse('2025-12-31'), project_type_numbers: [1] } },
    )
  end

  before do
    travel_to(Date.parse('2026-06-15'))
    setup_access_control(user, role, Collection.system_collection(:data_sources))
    settings.update!(map_type: 'place')
  end

  after { travel_back }

  describe '#snap_rate' do
    context 'with percentage-of-homeless-population bands' do
      before { settings.update!(map_overall_population_method: 'state') }

      it 'snaps each rate to the top of its band' do
        snapped = [0, 0.1, 10.0, 10.1, 25.0, 25.1].map { |rate| map_data.snap_rate(rate) }

        expect(snapped).to eq([0, 10.0, 10.0, 15.0, 25.0, 100.0])
      end

      it 'snaps a rate above every band to the top band' do
        expect(map_data.snap_rate(150.0)).to eq(100.0)
      end
    end

    context 'with census rate-per-10,000 bands' do
      before { settings.update!(map_overall_population_method: 'geography') }

      it 'snaps each rate to the top of its band' do
        snapped = [3.0, 3.1, 18.0, 18.1].map { |rate| map_data.snap_rate(rate) }

        expect(snapped).to eq([3.0, 6.0, 18.0, 100.0])
      end
    end
  end

  # town_map.js and _town_map.haml string-match these keys, the `Percentage` prefix of
  # `unit`, and band `max`/`color`/`label`; renaming any of them breaks the published page.
  describe '#to_h' do
    it 'emits the keys, percent unit and percent bands the town map reads' do
      settings.update!(map_overall_population_method: 'state')

      data = map_data.to_h

      expect(data.keys).to eq([:towns, :periods, :groups, :values, :populations, :statewideTotals, :bands, :notReportingColor, :unit, :map_type])
      expect(data[:bands].map(&:keys).uniq).to eq([[:max, :color, :label]])
      expect(data[:bands].map { |band| band[:max] }).to eq([0, 10.0, 15.0, 20.0, 25.0, 100.0])
      expect(data.values_at(:unit, :notReportingColor, :map_type)).to eq(['Percentage of homeless population', '#EDEDED', 'place'])
      expect([data[:values].size, data[:statewideTotals].size, data[:periods]]).to eq([4, 4, ['2025 Q1', '2025 Q2', '2025 Q3', '2025 Q4']])
    end

    it 'emits the per-10,000 unit and census bands in census mode' do
      settings.update!(map_overall_population_method: 'geography')

      data = map_data.to_h

      expect(data[:unit]).to eq('Rate per 10,000 population')
      expect(data[:bands].map { |band| band.values_at(:max, :label) }).to eq(
        [
          [0, 'None'],
          [3.0, 'Any - 3 per 10,000'],
          [6.0, '4 - 6 per 10,000'],
          [9.0, '7 - 9 per 10,000'],
          [12.0, '10 - 12 per 10,000'],
          [15.0, '13 - 15 per 10,000'],
          [18.0, '16 - 18 per 10,000'],
          [100.0, '19+ per 10,000'],
        ],
      )
    end
  end

  describe '#to_h with town shapes and enrollments' do
    let!(:state) { GrdaWarehouse::Shape::State.create!(stusps: 'MA', geoid: '25') }
    let(:data_source) { create(:data_source_fixed_id) }
    let(:organization) { create(:hud_organization, data_source_id: data_source.id) }
    let(:total_population_variable) do
      GrdaWarehouse::UsCensusApi::CensusVariable.create!(
        year: 2024, dataset: 'acs5', name: 'B01003_001E', label: 'POP::TOTAL', concept: 'Total Population',
        census_group: 'B01003', census_attributes: 'B01003_001EA', internal_name: 'POP::TOTAL', created_on: Date.current
      )
    end

    before do
      # GrdaWarehouse::Shape classes memoize their state-code lookup on the class object, so
      # a stale (pre-fixture) empty result from another example would hide every town.
      GrdaWarehouse::Shape::Town.instance_variable_set(:@my_fips_state_codes, nil)
    end

    # Geography#population reads the town's census value, so every shape needs one.
    def create_town(name, west:, population:)
      GrdaWarehouse::Shape::Town.create!(
        town: name,
        statefp: state.geoid,
        full_geoid: "CUSTOMTOWNUS#{name}",
        geom: "SRID=4326;MULTIPOLYGON(((#{west} 42.0, #{west + 0.1} 42.0, #{west + 0.1} 42.1, #{west} 42.1, #{west} 42.0)))",
      )
      GrdaWarehouse::UsCensusApi::CensusValue.create!(
        census_variable: total_population_variable, value: population, full_geoid: "CUSTOMTOWNUS#{name}", census_level: 'CUSTOM', created_on: Date.current,
      )
    end

    # One ES project whose ProjectCoC principal site is `city`, with `count` clients each served once in Q4 2025.
    def enroll_clients(count, city:)
      project = create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1)
      create(:hud_project_coc, data_source: data_source, ProjectID: project.ProjectID, City: city)
      count.times do |i|
        client = create(:hud_client, data_source_id: data_source.id)
        she = create(
          :she_entry,
          client: client,
          data_source_id: data_source.id,
          project_id: project.project_id,
          organization_id: project.organization_id,
          project_type: 1,
          date: Date.parse('2025-10-15'),
          first_date_in_program: Date.parse('2025-10-15'),
          last_date_in_program: Date.parse('2025-12-31'),
          household_id: "#{city}-#{i}",
          head_of_household: true,
        )
        create(
          :service_history_service,
          service_history_enrollment_id: she.id,
          client_id: client.id,
          record_type: 'service',
          date: Date.parse('2025-10-15'),
          project_type: 1,
          age: 30,
        )
      end
    end

    it 'floors a small town count to 11 before taking its share and leaves a town with no one at 0' do
      settings.update!(map_overall_population_method: 'state')
      create_town('EMPTYVILLE', west: -71.5, population: 10_000)
      create_town('TESTVILLE', west: -71.0, population: 10_000)
      enroll_clients(2, city: 'Testville')
      enroll_clients(48, city: 'Othertown')

      data = map_data.to_h

      # Testville: 2 of 50 statewide, floored to 11 -> 22% -> the 21%-25% band (25.0).
      # Without the floor it is 4% (10.0); counting enrollments regardless of city it is 100% (100.0).
      expect(data[:towns]).to eq(['EMPTYVILLE', 'TESTVILLE'])
      expect(data[:values].last.first).to eq([0, 25.0])
    end

    it 'reports nil for a town with no census population and a per-10,000 rate elsewhere in census mode' do
      settings.update!(map_overall_population_method: 'geography')
      create_town('OTHERTOWN', west: -71.5, population: 100_000)
      create_town('TESTVILLE', west: -71.0, population: 0)
      enroll_clients(48, city: 'Othertown')
      enroll_clients(2, city: 'Testville')

      data = map_data.to_h

      # Othertown: 48 people / (100,000 / 10,000) = 4.8 per 10,000 -> the 4-6 band (6.0). Testville has
      # people but no denominator, so it must be nil rather than 0.
      expect(data[:populations]).to eq([100_000, 0])
      expect(data[:values].last.first).to eq([6.0, nil])
    end
  end
end
