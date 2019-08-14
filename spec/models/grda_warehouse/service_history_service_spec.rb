require 'rails_helper'

RSpec.describe GrdaWarehouse::ServiceHistoryService, type: :model do
  before(:all) do
    @delete_later = []
    setup_initial_imports
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    Delayed::Worker.new.work_off(2)
  end
  after(:all) do
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
    # also clear out delayed job
    Delayed::Job.delete_all
  end

  it 'homeless services scope includes all services' do
    scope = GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: start_date, end_date: end_date)
    expect(scope.count).to eq(GrdaWarehouse::ServiceHistoryService.count)
  end

  it 'homeless no longer includes PH with no move-in-date' do
    en = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.where.not(TrackingMethod: 3)).first
    en.project.update(ProjectType: 13, computed_project_type: 13)
    en.update(processed_as: nil)
    en.rebuild_service_history!
    scope = GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: start_date, end_date: end_date)
    aggregate_failures do
      expect(en.service_history_enrollment.service_history_services.count).to be > 0
      expect(scope.count).to eq(GrdaWarehouse::ServiceHistoryService.count - en.service_history_enrollment.service_history_services.count)
      expect(GrdaWarehouse::ServiceHistoryService.where(homeless: nil).count).to eq en.service_history_enrollment.service_history_services.count
    end
  end

  it 'homeless no longer includes services for the entry exit enrollment if we make them PH with a prior move-in-date' do
    en = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.where.not(TrackingMethod: 3)).first
    en.project.update(ProjectType: 13, computed_project_type: 13)
    en.update(MoveInDate: start_date, processed_as: nil)
    en.rebuild_service_history!

    scope = GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: start_date, end_date: end_date)
    aggregate_failures do
      expect(en.service_history_enrollment.service_history_services.count).to be > 0
      expect(scope.count).to eq(GrdaWarehouse::ServiceHistoryService.count - en.service_history_enrollment.service_history_services.count)
    end
  end

  it 'homeless still includes TH with a future move-in-date' do
    en = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.where.not(TrackingMethod: 3)).first
    en.project.update(ProjectType: 2, computed_project_type: 2)
    en.update(MoveInDate: end_date + 1.days, processed_as: nil)
    en.rebuild_service_history!

    scope = GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: start_date, end_date: end_date)
    aggregate_failures do
      expect(en.service_history_enrollment.service_history_services.count).to be > 0
      expect(scope.count).to eq(GrdaWarehouse::ServiceHistoryService.count)
    end
  end

  it 'homeless still includes TH with a past move-in-date' do
    en = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.where.not(TrackingMethod: 3)).first
    en.project.update(ProjectType: 2, computed_project_type: 2)
    en.update(MoveInDate: start_date, processed_as: nil)
    en.rebuild_service_history!

    scope = GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: start_date, end_date: end_date)
    aggregate_failures do
      expect(en.service_history_enrollment.service_history_services.count).to be > 0
      expect(scope.count).to eq(GrdaWarehouse::ServiceHistoryService.count)
    end
  end

  it 'literally homeless does not include TH with a past move-in-date' do
    en = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.where.not(TrackingMethod: 3)).first
    en.project.update(ProjectType: 2, computed_project_type: 2)
    en.update(MoveInDate: start_date, processed_as: nil)
    en.rebuild_service_history!

    scope = GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: start_date, end_date: end_date)
    aggregate_failures do
      expect(en.service_history_enrollment.service_history_services.count).to be > 0
      expect(scope.count).to eq(GrdaWarehouse::ServiceHistoryService.count - en.service_history_enrollment.service_history_services.count)
    end
  end

  # FIXME
  # Add some move-in-dates, rebuild and re-check

  def start_date
    GrdaWarehouse::Hud::Enrollment.minimum(:EntryDate)
  end

  def end_date
    [GrdaWarehouse::Hud::Export.maximum(:effective_export_end_date), GrdaWarehouse::Hud::Exit.maximum(:ExitDate), GrdaWarehouse::Hud::Service.maximum(:DateProvided)].max
  end

  def setup_initial_imports
    ds_1 = GrdaWarehouse::DataSource.create(name: 'First Data Source', short_name: 'FDS', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'Warehouse', source_type: nil)
    {
      'spec/fixtures/files/service_history/tracking_methods' => ds_1,
    }.each do |path, data_source|
      source_file_path = File.join(path, 'source')
      import_path = File.join(path, data_source.id.to_s)
      # duplicate the fixture file as it gets manipulated
      FileUtils.cp_r(source_file_path, import_path)
      @delete_later << import_path unless import_path == source_file_path

      importer = Importers::HMISSixOneOne::Base.new(
        file_path: path,
        data_source_id: data_source.id,
        remove_files: false,
      )
      importer.import!
    end
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
  end
end
