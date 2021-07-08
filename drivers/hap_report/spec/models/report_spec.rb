###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HapReport::Report, type: :model do
  describe 'with all projects' do
    before(:all) do
      setup('drivers/hap_report/spec/fixtures/files/fy2020/default')
      @report = HapReport::Report.create!(
        options: {
          start: '2019-01-01'.to_date,
          end: '2019-12-31'.to_date,
          project_ids: GrdaWarehouse::Hud::Project.pluck(:id),
        },
      )
      @report.run_and_save!
    end

    after(:all) do
      cleanup
    end

    it 'finds households with children' do
      expect(value(:head_of_households_with_children, :total)).to eq(2)
    end

    it 'finds households without children' do
      expect(value(:head_of_adult_only_households, :total)).to eq(5)
    end

    it 'finds adult es clients' do
      expect(value(:adults_served, :emergency_shelter)).to eq(6)
    end

    it 'all adult clients are es' do
      expect(value(:adults_served, :total)).to eq(6)
    end

    it 'counts all clients' do
      expect(value(:total_clients_served, :total)).to eq(9)
    end
  end

  describe 'with just NBN projects' do
    before(:all) do
      setup('drivers/hap_report/spec/fixtures/files/fy2020/default')
      @report = HapReport::Report.create!(
        options: {
          start: '2019-01-01'.to_date,
          end: '2019-12-31'.to_date,
          project_ids: GrdaWarehouse::Hud::Project.night_by_night.pluck(:id),
        },
      )
      @report.run_and_save!
    end

    after(:all) do
      cleanup
    end

    it 'sees only one night' do
      expect(value(:total_units_of_shelter_service, :emergency_shelter)).to eq(1)
    end
  end

  def value(row, column)
    @report.cell("#{row}_#{column}").summary
  end

  def setup(file_path)
    @delete_later = []
    GrdaWarehouse::Utility.clear!

    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
    import(file_path, @data_source)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!

    Delayed::Worker.new.work_off(2)
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

  def cleanup
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    if @delete_later # rubocop:disable Style/SafeNavigation
      @delete_later.each do |path|
        FileUtils.rm_rf(path)
      end
    end
    Delayed::Job.delete_all
  end
end
