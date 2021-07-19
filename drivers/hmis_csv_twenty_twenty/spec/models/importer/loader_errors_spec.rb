###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  before(:all) do
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!

    travel_to Time.local(2020, 1, 1) do
      @loader = import_hmis_csv_fixture(
        'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/loader_errors',
        version: '2020',
        run_jobs: false,
      )
    end

    @client_rows = 134
    @client_rows_with_errors = 3
    @expected_client_rows = @client_rows - @client_rows_with_errors
  end

  it 'the database will have the correct number of source clients' do
    expect(GrdaWarehouse::Hud::Client.source.count).to eq(@expected_client_rows)
  end

  it 'all clients would have last names' do
    expect(GrdaWarehouse::Hud::Client.source.where.not(LastName: nil).count).to eq(@expected_client_rows)
  end

  it 'the project loaded' do
    expect(GrdaWarehouse::Hud::Project.count).to eq(1)
  end

  it 'load errors are generated for the too many columns' do
    errors = @loader.loader_log.load_errors.select do |e|
      e.file_name == 'Client.csv' && e.message =~ /too many/i
    end.sort_by(&:id)
    expect(errors.map(&:details)).to eq(['Line number: 7', 'Line number: 34', 'Line number: 61'])
  end

  it 'load errors are generated for two few columns' do
    errors = @loader.loader_log.load_errors.select do |e|
      e.file_name == 'Event.csv' && e.message =~ /too few/i
    end.sort_by(&:id)
    expect(errors.map(&:details)).to eq(['Line number: 3'])
  end

  it 'counts lines/records correctly with skipped rows' do
    stats = @loader.loader_log.summary['Client.csv']
    expect(stats['total_lines']).to eq(@client_rows)
    expect(stats['lines_loaded']).to eq(@expected_client_rows)
  end

  it 'load errors are generated for a invalid header' do
    errors = @loader.loader_log.load_errors.select { |e| e.file_name == 'Exit.csv' }
    expect(errors.size).to eq(2)
    assert(errors.first.details =~ /header row incorrect/i)
    assert(errors.last.details =~ /found extra columns/i)
  end
end
