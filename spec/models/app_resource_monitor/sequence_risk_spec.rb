###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppResourceMonitor::SequenceRisk, type: :model do
  let(:key) { 'stats/clientname-production/postgres_sequence_stats-20261114120000.csv' }
  let(:rows) do
    [
      sequence_row(database: 'warehouse', tablename: 'clients', pct_used: '12.5000'),
      sequence_row(database: 'warehouse', tablename: 'enrollments', pct_used: '87.2500'),
      sequence_row(database: 'app', tablename: 'users', pct_used: '50.0000'),
    ]
  end

  def sequence_row(database:, tablename:, pct_used:)
    {
      'database' => database,
      'tablename' => tablename,
      'column_name' => 'id',
      'last_value' => '100',
      'max_value' => '2147483647',
      'capacity_limited_by' => 'sequence',
      'pct_used' => pct_used,
    }
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def build_report(database: nil)
    report = described_class.new(
      prefix: 'clientname-production',
      database: database,
    )
    allow(report).to receive(:validate_config!)
    allow(report).to receive(:nearest_key).with('postgres_sequence_stats', anything).and_return(key)
    allow(report).to receive(:parse_csv).with(key).and_return(rows)
    report
  end

  it 'lists sequences from highest to lowest percent used' do
    report = build_report

    expect { report.run }.to output(/enrollments\.id.*users\.id.*clients\.id/m).to_stdout
  end

  it 'shows only the requested database' do
    report = build_report(database: 'app')

    printed = capture_stdout { report.run }

    expect(printed).to include('users.id')
    expect(printed).not_to include('clients.id')
    expect(printed).not_to include('enrollments.id')
  end

  it 'raises on a database that is not in the snapshot' do
    report = build_report(database: 'warehouse_typo')

    expect { report.run }.to raise_error(
      AppResourceMonitor::S3Analysis::ConfigurationError,
      /No database named 'warehouse_typo'.*Available: warehouse, app/,
    )
  end
end
