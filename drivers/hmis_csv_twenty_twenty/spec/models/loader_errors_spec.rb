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
    @delete_later = []
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/loader_errors'
    travel_to Time.local(2020, 1, 1) do
      import(file_path, @data_source)
    end

    @client_rows = 134
    @client_rows_with_errors = 3
    @expected_client_rows = @client_rows - @client_rows_with_errors
  end

  after(:all) do
    # Because we are only running the import once, we have to do our own DB and file cleanup
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!
    cleanup_files
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

  it 'load errors are generated for the invalid rows' do
    errors = @loader.loader_log.load_errors.select do |e|
      e.file_name == 'Client.csv' && e.message =~ /extra columns/i
    end.sort_by(&:id)
    expect(errors.map(&:details)).to eq(['lineno: 7', 'lineno: 34', 'lineno: 61'])
  end

  it 'counts lines/records correctly with skipped rows' do
    stats = @loader.loader_log.summary['Client.csv']
    expect(stats['total_lines']).to eq(@client_rows + 1)
    expect(stats['lines_loaded']).to eq(@expected_client_rows)
  end

  it 'load errors are generated for a invalid header' do
    errors = @loader.loader_log.load_errors.select { |e| e.file_name == 'Exit.csv' }
    expect(errors.size).to eq(1)
    expect(errors.first.message =~ /Header invalid/i)
  end

  def import(file_path, data_source)
    source_file_path = File.join(file_path, 'source')
    import_path = File.join(file_path, data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(source_file_path, import_path)
    @delete_later << import_path unless import_path == source_file_path

    @loader = HmisCsvTwentyTwenty::Loader::Loader.new(
      file_path: import_path,
      data_source_id: data_source.id,
      remove_files: false,
    )
    @loader.load!
    @loader.import!
  end

  def cleanup_files
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
  end
end
