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

  it 'breaks a same-day tie by the lower id' do
    client = create(:grda_warehouse_hud_client, data_source: data_source)
    first_row = build_row(client: client, first: Date.new(2025, 7, 1))
    build_row(client: client, first: Date.new(2025, 7, 1))

    expect(result_ids).to contain_exactly(first_row.id)
  end

  it 'drops scope rows that are not open in the range' do
    client = create(:grda_warehouse_hud_client, data_source: data_source)
    build_row(client: client, first: Date.new(2024, 1, 1), last: Date.new(2024, 6, 30))

    expect(result_ids).to be_empty
  end

  it 'picks the first enrollment before applying the report filter' do
    client = create(:grda_warehouse_hud_client, data_source: data_source)
    build_row(client: client, first: Date.new(2025, 2, 1), project_type: 6)
    build_row(client: client, first: Date.new(2025, 3, 1), project_type: 1)

    expect(result_ids(entries.where(project_type: 1))).to be_empty
  end
end
