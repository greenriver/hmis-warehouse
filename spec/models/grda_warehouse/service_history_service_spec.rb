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
    start_date = GrdaWarehouse::Hud::Enrollment.minimum(:EntryDate)
    end_date = [GrdaWarehouse::Hud::Export.maximum(:effective_export_end_date), GrdaWarehouse::Hud::Exit.maximum(:ExitDate), GrdaWarehouse::Hud::Service.maximum(:DateProvided)].max
    scope = GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: start_date, end_date: end_date)
    expect(scope.count).to eq(GrdaWarehouse::ServiceHistoryService.count)
  end

  it 'no longer includes services for the entry exit enrollment if we make them PH' do
    en = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.where.not(TrackingMethod: 3)).first
    en.project.update(ProjectType: 13, computed_project_type: 13)
    en.update(processed_as: nil)
    en.rebuild_service_history!

    start_date = GrdaWarehouse::Hud::Enrollment.minimum(:EntryDate)
    end_date = [GrdaWarehouse::Hud::Exit.maximum(:ExitDate), GrdaWarehouse::Hud::Service.maximum(:DateProvided)].max
    scope = GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: start_date, end_date: end_date)
    expect(scope.count).to eq(GrdaWarehouse::ServiceHistoryService.count - en.service_history_enrollment.service_history_services.count)
  end

  # FIXME
  # Add some move-in-dates, rebuild and re-check

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

  # let(:client) { 0 }
  # let(:start_date) { Date.today }
  # let(:end_date) { Date.tomorrow }
  # let!(:data_source) { create :data_source_fixed_id }

  # let!(:no_move_in) { create :grda_warehouse_service_history, :service_history_entry, client_id: 1, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
  # let!(:no_move_in_enrollment) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 1, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
  # let!(:no_move_in_services) { create_services_for no_move_in }
  # let!(:no_move_in_enrollment_services) { create_services_for no_move_in_enrollment }

  # let!(:future_move_in) { create :grda_warehouse_service_history, :service_history_entry, client_id: 2, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
  # let!(:future_move_in_enrollment) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 2, data_source_id: 1, move_in_date: Date.tomorrow, first_date_in_program: start_date, last_date_in_program: end_date }
  # let!(:future_move_in_services) { create_services_for future_move_in }
  # let!(:future_move_in_enrollment_services) { create_services_for future_move_in_enrollment }

  # let!(:past_move_in) { create :grda_warehouse_service_history, :service_history_entry, client_id: 3, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
  # let!(:past_move_in_enrollment) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 3, data_source_id: 1, move_in_date: Date.yesterday, first_date_in_program: start_date, last_date_in_program: end_date }
  # let!(:past_move_in_services) { create_services_for past_move_in }
  # let!(:past_move_in_enrollment_services) { create_services_for past_move_in_enrollment }

  # it 'has services for all enrollment days' do
  #   expect(GrdaWarehouse::ServiceHistoryService.all).to include(*no_move_in_services)
  #   expect(GrdaWarehouse::ServiceHistoryService.all).to include(*future_move_in_services)
  #   expect(GrdaWarehouse::ServiceHistoryService.all).to include(*past_move_in_services)
  # end

  # describe 'homeless only' do
  #   let(:scope) { GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: start_date, end_date: end_date) }

  #   it 'includes no move in' do
  #     expect(scope).to include(*no_move_in_services)
  #   end

  #   it 'includes future move in' do
  #     expect(scope).to include(*future_move_in_services)
  #   end

  #   it 'does not include past move in' do
  #     expect(scope).not_to include(*past_move_in_services)
  #   end
  # end

  # def create_services_for(enrollment)
  #   binding.pry

  #   services = []
  #   (enrollment.first_date_in_program..enrollment.last_date_in_program).map do |date|
  #     GrdaWarehouse::ServiceHistoryService.create!(
  #       record_type: 'service',
  #       service_history_enrollment: enrollment,
  #       client_id: enrollment.client_id,
  #       project_type: enrollment.computed_project_type,
  #       date: date,
  #     )
  #     services << GrdaWarehouse::ServiceHistoryService.last
  #   end
  #   services
  # end
end
