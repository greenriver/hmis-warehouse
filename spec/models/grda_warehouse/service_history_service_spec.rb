require 'rails_helper'

RSpec.describe GrdaWarehouse::ServiceHistoryService, type: :model do
  before(:all) do
    import_hmis_csv_fixture(
      'spec/fixtures/files/service_history/tracking_methods',
      version: 'AutoMigrate',
    )
  end
  after(:all) do
    GrdaWarehouse::Utility.clear!
    cleanup_hmis_csv_fixtures
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

  def start_date
    GrdaWarehouse::Hud::Enrollment.minimum(:EntryDate)
  end

  def end_date
    [GrdaWarehouse::Hud::Export.maximum(:effective_export_end_date), GrdaWarehouse::Hud::Exit.maximum(:ExitDate), GrdaWarehouse::Hud::Service.maximum(:DateProvided)].max
  end
end
