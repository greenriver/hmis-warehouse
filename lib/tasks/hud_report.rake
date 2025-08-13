###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  # desc "Build Measure 1 - HUD System Performance Measures"
  # task :measure_1 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::SystemPerformance::Fy2015::MeasureOne.new.run!
  # end

  # desc "Queue Measure 1 - HUD System Performance Measures"
  # task :queue_measure_1 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureOne.first, percent_complete: 0)
  # end

  # desc "Build Measure 2 - HUD System Performance Measures"
  # task :measure_2 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::SystemPerformance::Fy2015::MeasureTwo.new.run!
  # end

  # desc "Queue Measure 2 - HUD System Performance Measures"
  # task :queue_measure_2 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureTwo.first, percent_complete: 0)
  # end

  # desc "Build Measure 3 - HUD System Performance Measures"
  # task :measure_3 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::SystemPerformance::Fy2015::MeasureThree.new.run!
  # end

  # desc "Queue Measure 3 - HUD System Performance Measures"
  # task :queue_measure_3 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureThree.first, percent_complete: 0)
  # end

  # desc "Build Measure 4 - HUD System Performance Measures"
  # task :measure_4 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::SystemPerformance::Fy2015::MeasureFour.new.run!
  # end

  # desc "Queue Measure 4 - HUD System Performance Measures"
  # task :queue_measure_4 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureFour.first, percent_complete: 0)
  # end

  # desc "Build Measure 5 - HUD System Performance Measures"
  # task :measure_5 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::SystemPerformance::Fy2015::MeasureFive.new.run!
  # end

  # desc "Queue Measure 5 - HUD System Performance Measures"
  # task :queue_measure_5 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureFive.first, percent_complete: 0)
  # end

  # desc "Build Measure 6 - HUD System Performance Measures"
  # task :measure_6 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::SystemPerformance::Fy2015::MeasureSix.new.run!
  # end

  # desc "Queue Measure 6 - HUD System Performance Measures"
  # task :queue_measure_6 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureSix.first, percent_complete: 0)
  # end

  # desc "Build Measure 7 - HUD System Performance Measures"
  # task :measure_7 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::SystemPerformance::Fy2015::MeasureSeven.new.run!
  # end

  # desc "Queue Measure 7 - HUD System Performance Measures"
  # task :queue_measure_7 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::SystemPerformance::Fy2015::MeasureSeven.first, percent_complete: 0)
  # end

  # desc "Queue 2016 AHAR - HUD Annual Homeless Assessment Report"
  # task :queue_ahar_2016 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::Ahar::Fy2016::Base.first, percent_complete: 0)
  # end

  # desc "Queue 2016 Veteran AHAR - HUD Annual Homeless Assessment Report"
  # task :queue_ahar_veteran_2016 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::Ahar::Fy2016::Veteran.first, percent_complete: 0)
  # end

  # desc "Queue 2016 AHAR By Project - HUD Annual Homeless Assessment Report"
  # task :queue_ahar_by_project_2016 => [:environment, "log:info_to_stdout"] do
  #   ReportResult.create(report: Reports::Ahar::Fy2016::ByProject.first, percent_complete: 0)
  # end

  # desc "Build 2016 AHAR - HUD Annual Homeless Assessment Report"
  # task :ahar_2016 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::Ahar::Fy2016::Base.new.run!
  # end

  # desc "Build 2016 Veteran AHAR - HUD Annual Homeless Assessment Report"
  # task :ahar_veteran_2016 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::Ahar::Fy2016::Veteran.new.run!
  # end

  # desc "Build 2016 AHAR By Project - HUD Annual Homeless Assessment Report"
  # task :ahar_by_project_2016 => [:environment, "log:info_to_stdout"] do
  #   ReportGenerators::Ahar::Fy2016::ByProject.new.run!
  # end

  # Process a single HUD report: store artifacts (shards) and cleanup RDS
  # Usage:
  #   rake hud_reports:store_hud_report_data[REPORT_ID]
  #   rake "hud_reports:store_hud_report_data[REPORT_ID,true]"  # dry run
  desc 'Process a single HUD report (store to S3 and cleanup RDS). Optional dry_run=true to preview only.'
  task :store_hud_report_data, [:report_id, :dry_run] => :environment do |_t, args|
    report_id = args[:report_id]
    dry_run = ['true', '1', 'yes'].include?(args[:dry_run].to_s.downcase)

    if report_id.blank?
      puts 'Usage: rake hud_reports:store_hud_report_data[REPORT_ID,DRY_RUN]'
      exit 1
    end

    report = HudReports::ReportInstance.find(report_id)

    if dry_run
      puts "DRY RUN: Would process report #{report.id} - #{report.report_name} (completed: #{report.completed_at})"
      puts 'DRY RUN: Would store artifacts (shards) and cleanup RDS data'
      next
    end

    HudReports::StoreArtifactsAndCleanupJob.perform_now(report.id)
    puts "Processed report #{report.id}"
  rescue ActiveRecord::RecordNotFound
    puts "Report #{report_id} not found"
    exit 1
  end

  # Process all completed HUD reports not yet processed
  # Usage:
  #   rake hud_reports:store_all_hud_report_data
  #   rake "hud_reports:store_all_hud_report_data[true]"  # dry run
  desc 'Process all completed HUD reports (store to S3 and cleanup RDS). Optional dry_run=true to preview only.'
  task :store_all_hud_report_data, [:dry_run] => :environment do |_t, args|
    dry_run = ['true', '1', 'yes'].include?(args[:dry_run].to_s.downcase)

    scope = HudReports::ReportInstance.
      where.not(completed_at: nil).
      where(artifacts_stored_at: nil).
      order(:completed_at)

    if dry_run
      puts "DRY RUN: Would process #{scope.count} completed reports"
      next
    end

    processed = 0

    scope.find_each do |report|
      HudReports::StoreArtifactsAndCleanupJob.perform_now(report.id)
      processed += 1
      puts "  Processed report #{report.id}"
    end

    puts "Processing completed: #{processed} processed"
  end
end
