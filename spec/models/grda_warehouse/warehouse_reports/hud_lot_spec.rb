require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::HudLot, type: :model do
  let(:filter) { Filters::DateRange.new(start: '2017-01-01'.to_date, end: '2019-12-31'.to_date) }

  before(:all) do
    import_hmis_csv_fixture('spec/fixtures/files/hud_lot/enrollments')
  end

  after(:all) do
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    cleanup_hmis_csv_fixtures
    Delayed::Job.delete_all
  end

  # NOTE: these tests are by no means exhaustive
  it 'has certain dates to have known types' do
    client = GrdaWarehouse::Hud::Client.destination.joins(:source_enrollments).first
    report = GrdaWarehouse::WarehouseReports::HudLot.new(filter: filter, client: client)
    expect(report.locations_by_date.select { |_, v| v.present? }.count).to be > 0
    expect(report.locations_by_date['2017-12-10'.to_date]).to eq(report.shelter_stay)
    expect(report.locations_by_date['2017-12-11'.to_date]).to eq(report.shelter_stay)
    expect(report.locations_by_date['2018-05-10'.to_date]).to eq(report.self_reported_shelter)
    expect(report.locations_by_date['2018-05-11'.to_date]).to eq(report.self_reported_break)
    expect(report.locations_by_date['2018-05-12'.to_date]).to eq(report.shelter_stay)
    expect(report.locations_by_date['2019-03-14'.to_date]).to eq(report.ph_stay)
  end
end
