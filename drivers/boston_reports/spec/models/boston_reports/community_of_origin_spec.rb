###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BostonReports::CommunityOfOrigin, '.earliest_enrollment_per_client', type: :model do
  let(:start_date) { Date.new(2025, 1, 1) }
  let(:end_date) { Date.new(2025, 12, 31) }
  let(:entries) { GrdaWarehouse::ServiceHistoryEnrollment.entry }
  let(:data_source) { create(:grda_warehouse_data_source) }

  def build_row(client:, first:, last: nil, record_type: 'entry', project_type: 1)
    create(
      :grda_warehouse_service_history,
      client: client,
      data_source: data_source,
      record_type: record_type,
      first_date_in_program: first,
      last_date_in_program: last,
      project_type: project_type,
    )
  end

  def result_ids(scope = entries)
    described_class.earliest_enrollment_per_client(scope, start_date: start_date, end_date: end_date).pluck(:id)
  end

  it 'keeps the earliest open entry for each client' do
    client_1 = create(:grda_warehouse_hud_client, data_source: data_source)
    client_2 = create(:grda_warehouse_hud_client, data_source: data_source)
    march = build_row(client: client_1, first: Date.new(2025, 3, 1))
    build_row(client: client_1, first: Date.new(2025, 5, 1))
    single = build_row(client: client_2, first: Date.new(2025, 6, 1))

    expect(result_ids).to contain_exactly(march.id, single.id)
  end

  it 'ignores entries that closed before the range' do
    client = create(:grda_warehouse_hud_client, data_source: data_source)
    build_row(client: client, first: Date.new(2024, 1, 1), last: Date.new(2024, 6, 30))
    february = build_row(client: client, first: Date.new(2025, 2, 1))

    expect(result_ids).to contain_exactly(february.id)
  end

  it 'ignores exit rows' do
    client = create(:grda_warehouse_hud_client, data_source: data_source)
    build_row(client: client, first: Date.new(2025, 1, 5), record_type: 'exit')
    entry = build_row(client: client, first: Date.new(2025, 4, 1))

    expect(result_ids).to contain_exactly(entry.id)
  end

  describe 'same-day entries' do
    let(:client) { create(:grda_warehouse_hud_client, data_source: data_source) }
    let(:day) { Date.new(2025, 7, 1) }

    it 'keeps the entry with no exit date' do
      build_row(client: client, first: day, last: Date.new(2025, 9, 1))
      open = build_row(client: client, first: day, last: nil)

      expect(result_ids).to contain_exactly(open.id)
    end

    it 'keeps the later exit date' do
      build_row(client: client, first: day, last: Date.new(2025, 8, 1))
      later = build_row(client: client, first: day, last: Date.new(2025, 10, 1))

      expect(result_ids).to contain_exactly(later.id)
    end

    it 'keeps the lower id when exit dates match' do
      exit_date = Date.new(2025, 9, 1)
      first_row = build_row(client: client, first: day, last: exit_date)
      build_row(client: client, first: day, last: exit_date)

      expect(result_ids).to contain_exactly(first_row.id)
    end

    it 'ignores a same-day entry outside the scope even when it has no exit date' do
      in_scope = build_row(client: client, first: day, last: Date.new(2025, 8, 1), project_type: 1)
      build_row(client: client, first: day, last: nil, project_type: 6)

      expect(result_ids(entries.where(project_type: 1))).to contain_exactly(in_scope.id)
    end

    it 'ranks the in-scope entries by exit date' do
      build_row(client: client, first: day, last: Date.new(2025, 8, 1), project_type: 1)
      later = build_row(client: client, first: day, last: Date.new(2025, 10, 1), project_type: 4)
      build_row(client: client, first: day, last: nil, project_type: 6)

      expect(result_ids(entries.where(project_type: [1, 4]))).to contain_exactly(later.id)
    end

    it 'keeps the lower id when neither has an exit date' do
      first_row = build_row(client: client, first: day)
      build_row(client: client, first: day)

      expect(result_ids).to contain_exactly(first_row.id)
    end
  end

  it 'drops scope rows that are not open in the range' do
    client = create(:grda_warehouse_hud_client, data_source: data_source)
    build_row(client: client, first: Date.new(2024, 1, 1), last: Date.new(2024, 6, 30))

    expect(result_ids).to be_empty
  end

  it 'ignores an earlier entry outside the scope' do
    client = create(:grda_warehouse_hud_client, data_source: data_source)
    build_row(client: client, first: Date.new(2025, 2, 1), project_type: 6)
    march = build_row(client: client, first: Date.new(2025, 3, 1), project_type: 1)

    expect(result_ids(entries.where(project_type: 1))).to contain_exactly(march.id)
  end
end
