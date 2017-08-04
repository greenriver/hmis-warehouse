namespace :hud_report do
  # desc "Cleanup Bad Head of Households"
  # task :cleanup_bad_head_of_households => [:environment, "log:info_to_stdout"] do
  #   OldWarehouse::CleanupBadHeadOfHouseholds.new.run!
  # end

  # desc "NEW Generate Unique Client IDs"
  # task :generate_client_unique_ids => [:environment, "log:info_to_stdout"] do
  #   OldWarehouse::GenerateClientUniqueIds.new.run!
  # end

  # desc "NEW Generate daily client housing"
  # task :generate_all_daily_client_housing, [:newest_date] => [:environment, "log:info_to_stdout"] do |t, args|
  #   OldWarehouse::GenerateDailyClientHousing.new(args.newest_date).run!
  # end

  # desc "Import CSV of Client Housing History"
  # task :import_client_housing_history_csv => [:environment, "log:info_to_stdout"] do |t, args|
  #   OldWarehouse::ImportClientHousingHistoryCsv.new(args[:import_id]).run!
  # end
  
  desc "Build Measure 1 - HUD System Performance Measures"
  task :measure_1 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::SystemPerformance::Fy2015::MeasureOne.new.run!
  end

  desc "Queue Measure 1 - HUD System Performance Measures"
  task :queue_measure_1 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureOne.first, percent_complete: 0)
  end
  
  desc "Build Measure 2 - HUD System Performance Measures"
  task :measure_2 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::SystemPerformance::Fy2015::MeasureTwo.new.run!
  end

  desc "Queue Measure 2 - HUD System Performance Measures"
  task :queue_measure_2 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureTwo.first, percent_complete: 0)
  end

  desc "Build Measure 3 - HUD System Performance Measures"
  task :measure_3 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::SystemPerformance::Fy2015::MeasureThree.new.run!
  end

  desc "Queue Measure 3 - HUD System Performance Measures"
  task :queue_measure_3 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureThree.first, percent_complete: 0)
  end

  desc "Build Measure 4 - HUD System Performance Measures"
  task :measure_4 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::SystemPerformance::Fy2015::MeasureFour.new.run!
  end

  desc "Queue Measure 4 - HUD System Performance Measures"
  task :queue_measure_4 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureFour.first, percent_complete: 0)
  end

  desc "Build Measure 5 - HUD System Performance Measures"
  task :measure_5 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::SystemPerformance::Fy2015::MeasureFive.new.run!
  end

  desc "Queue Measure 5 - HUD System Performance Measures"
  task :queue_measure_5 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureFive.first, percent_complete: 0)
  end

  desc "Build Measure 6 - HUD System Performance Measures"
  task :measure_6 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::SystemPerformance::Fy2015::MeasureSix.new.run!
  end

  desc "Queue Measure 6 - HUD System Performance Measures"
  task :queue_measure_6 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureSix.first, percent_complete: 0)
  end

  desc "Build Measure 7 - HUD System Performance Measures"
  task :measure_7 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::SystemPerformance::Fy2015::MeasureSeven.new.run!
  end

  desc "Queue Measure 7 - HUD System Performance Measures"
  task :queue_measure_7 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureSeven.first, percent_complete: 0)
  end

  desc "Queue 2016 AHAR - HUD Annual Homeless Assessment Report"
  task :queue_ahar_2016 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::Ahar::Fy2016::Base.first, percent_complete: 0)
  end

  desc "Queue 2016 Veteran AHAR - HUD Annual Homeless Assessment Report"
  task :queue_ahar_veteran_2016 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::Ahar::Fy2016::Veteran.first, percent_complete: 0)
  end

  desc "Queue 2016 AHAR By Project - HUD Annual Homeless Assessment Report"
  task :queue_ahar_by_project_2016 => [:environment, "log:info_to_stdout"] do
    ReportResult.create(report: Reports::Ahar::Fy2016::ByProject.first, percent_complete: 0)
  end

  desc "Build 2016 AHAR - HUD Annual Homeless Assessment Report"
  task :ahar_2016 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::Ahar::Fy2016::Base.new.run!
  end

  desc "Build 2016 Veteran AHAR - HUD Annual Homeless Assessment Report"
  task :ahar_veteran_2016 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::Ahar::Fy2016::Veteran.new.run!
  end

  desc "Build 2016 AHAR By Project - HUD Annual Homeless Assessment Report"
  task :ahar_by_project_2016 => [:environment, "log:info_to_stdout"] do
    ReportGenerators::Ahar::Fy2016::ByProject.new.run!
  end

end