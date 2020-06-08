require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::HudLot, type: :model do
  let(:filter) { Filters::DateRange.new(start: '2017-01-01'.to_date, end: '2019-12-31'.to_date) }

  before(:all) do
    @delete_later = []
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
    file_path = 'spec/fixtures/files/hud_lot/enrollments'
    import(file_path, @data_source)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!

    Delayed::Worker.new.work_off(2)
  end

  after(:all) do
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    cleanup_files
    Delayed::Job.delete_all
  end

  # NOTE: these tests are by no means exhaustive
  it 'has certain dates to have known types' do
    client = GrdaWarehouse::Hud::Client.destination.joins(:source_enrollments).first
    report = GrdaWarehouse::WarehouseReports::HudLot.new(filter: filter, client: client)
    expect(report.locations_by_date.select { |_, v| v.present? }.count).to be > 0
    expect(report.locations_by_date['2017-12-11'.to_date]).to eq(report.shelter_stay)
    expect(report.locations_by_date['2018-05-10'.to_date]).to eq(report.self_reported_shelter)
    expect(report.locations_by_date['2018-05-11'.to_date]).to eq(report.self_reported_break)
    expect(report.locations_by_date['2018-05-12'.to_date]).to eq(report.shelter_stay)
    expect(report.locations_by_date['2019-03-14'.to_date]).to eq(report.ph_stay)
  end

  def import(file_path, data_source)
    source_file_path = File.join(file_path, 'source')
    import_path = File.join(file_path, data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(source_file_path, import_path)
    @delete_later << import_path unless import_path == source_file_path

    importer = Importers::HmisTwentyTwenty::Base.new(file_path: file_path, data_source_id: data_source.id, remove_files: false)
    importer.import!
  end

  def cleanup_files
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
  end
end
