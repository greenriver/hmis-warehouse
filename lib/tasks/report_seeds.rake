# Add a bunch a reports
namespace :reports do
  desc "Load Available Report Types"
  task :seed => [:environment, "log:info_to_stdout"] do
      # Summary
      # rs = ReportResultsSummaries::SystemPerformance::Fy2015.where(name: 'HUD System Performance FY 2015').first_or_create
      # rs.update(weight: 0)

      # r = Reports::SystemPerformance::Fy2015::MeasureOne.where(name: 'HUD System Performance FY 2015 - Measure 1').first_or_create
      # r.update(weight: 1, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2015::MeasureTwo.where(name: 'HUD System Performance FY 2015 - Measure 2').first_or_create
      # r.update(weight: 2, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2015::MeasureThree.where(name: 'HUD System Performance FY 2015 - Measure 3').first_or_create
      # r.update(weight: 3, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2015::MeasureFour.where(name: 'HUD System Performance FY 2015 - Measure 4').first_or_create
      # r.update(weight: 4, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2015::MeasureFive.where(name: 'HUD System Performance FY 2015 - Measure 5').first_or_create
      # r.update(weight: 5, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2015::MeasureSix.where(name: 'HUD System Performance FY 2015 - Measure 6').first_or_create
      # r.update(weight: 6, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2015::MeasureSeven.where(name: 'HUD System Performance FY 2015 - Measure 7').first_or_create
      # r.update(weight: 7, report_results_summary: rs)

      # rs = ReportResultsSummaries::SystemPerformance::Fy2016.where(name: 'HUD System Performance FY 2016').first_or_create
      # rs.update(weight: 0)

      # r = Reports::SystemPerformance::Fy2016::MeasureOne.where(name: 'HUD System Performance FY 2016 - Measure 1').first_or_create
      # r.update(weight: 1, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2016::MeasureTwo.where(name: 'HUD System Performance FY 2016 - Measure 2').first_or_create
      # r.update(weight: 2, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2016::MeasureThree.where(name: 'HUD System Performance FY 2016 - Measure 3').first_or_create
      # r.update(weight: 3, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2016::MeasureFour.where(name: 'HUD System Performance FY 2016 - Measure 4').first_or_create
      # r.update(weight: 4, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2016::MeasureFive.where(name: 'HUD System Performance FY 2016 - Measure 5').first_or_create
      # r.update(weight: 5, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2016::MeasureSix.where(name: 'HUD System Performance FY 2016 - Measure 6').first_or_create
      # r.update(weight: 6, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2016::MeasureSeven.where(name: 'HUD System Performance FY 2016 - Measure 7').first_or_create
      # r.update(weight: 7, report_results_summary: rs)
      #
      # rs = ReportResultsSummaries::SystemPerformance::Fy2017.where(name: 'HUD System Performance FY 2017').first_or_create
      # rs.update(weight: 0)
      #
      # r = Reports::SystemPerformance::Fy2017::MeasureOne.where(name: 'HUD System Performance FY 2017 - Measure 1').first_or_create
      # r.update(weight: 1, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2017::MeasureTwo.where(name: 'HUD System Performance FY 2017 - Measure 2').first_or_create
      # r.update(weight: 2, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2017::MeasureThree.where(name: 'HUD System Performance FY 2017 - Measure 3').first_or_create
      # r.update(weight: 3, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2017::MeasureFour.where(name: 'HUD System Performance FY 2017 - Measure 4').first_or_create
      # r.update(weight: 4, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2017::MeasureFive.where(name: 'HUD System Performance FY 2017 - Measure 5').first_or_create
      # r.update(weight: 5, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2017::MeasureSix.where(name: 'HUD System Performance FY 2017 - Measure 6').first_or_create
      # r.update(weight: 6, report_results_summary: rs)
      # r = Reports::SystemPerformance::Fy2017::MeasureSeven.where(name: 'HUD System Performance FY 2017 - Measure 7').first_or_create
      # r.update(weight: 7, report_results_summary: rs)

      rs = ReportResultsSummaries::SystemPerformance::Fy2018.where(name: 'HUD System Performance FY 2018').first_or_create
      rs.update(weight: 0)

      r = Reports::SystemPerformance::Fy2018::MeasureOne.where(name: 'HUD System Performance FY 2018 - Measure 1').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2018::MeasureTwo.where(name: 'HUD System Performance FY 2018 - Measure 2').first_or_create
      r.update(weight: 2, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2018::MeasureThree.where(name: 'HUD System Performance FY 2018 - Measure 3').first_or_create
      r.update(weight: 3, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2018::MeasureFour.where(name: 'HUD System Performance FY 2018 - Measure 4').first_or_create
      r.update(weight: 4, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2018::MeasureFive.where(name: 'HUD System Performance FY 2018 - Measure 5').first_or_create
      r.update(weight: 5, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2018::MeasureSix.where(name: 'HUD System Performance FY 2018 - Measure 6').first_or_create
      r.update(weight: 6, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2018::MeasureSeven.where(name: 'HUD System Performance FY 2018 - Measure 7').first_or_create
      r.update(weight: 7, report_results_summary: rs)

      rs = ReportResultsSummaries::Ahar::Fy2016.where(name: 'Annual Homeless Assessment Report - FY 2016').first_or_create
      rs.update(weight: 0)
      r = Reports::Ahar::Fy2016::Base.where(name: 'AHAR').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::Ahar::Fy2016::Veteran.where(name: 'Veteran AHAR').first_or_create
      r.update(weight: 2, report_results_summary: rs)
      r = Reports::Ahar::Fy2016::ByProject.where(name: 'AHAR By Project').first_or_create
      r.update(weight: 3, report_results_summary: rs)
      r = Reports::Ahar::Fy2016::ByDataSource.where(name: 'AHAR By Data Source').first_or_create
      r.update(weight: 4, report_results_summary: rs)

      rs = ReportResultsSummaries::Ahar::Fy2017.where(name: 'Annual Homeless Assessment Report - FY 2017').first_or_create
      rs.update(weight: 0)
      r = Reports::Ahar::Fy2017::Base.where(name: 'AHAR - 2017').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::Ahar::Fy2017::Veteran.where(name: 'Veteran AHAR - 2017').first_or_create
      r.update(weight: 2, report_results_summary: rs)
      r = Reports::Ahar::Fy2017::ByProject.where(name: 'AHAR By Project - 2017').first_or_create
      r.update(weight: 3, report_results_summary: rs)
      r = Reports::Ahar::Fy2017::ByDataSource.where(name: 'AHAR By Data Source - 2017').first_or_create
      r.update(weight: 4, report_results_summary: rs)

      rs = ReportResultsSummaries::Pit::Fy2017.where(name: 'Point in Time Counts - FY 2017').first_or_create
      rs.update(weight: 0)
      r = Reports::Pit::Fy2017::Base.where(name: 'PIT').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::Pit::Fy2017::ByProject.where(name: 'PIT By Project').first_or_create
      r.update(weight: 2, report_results_summary: rs)

      rs = ReportResultsSummaries::Pit::Fy2018.where(name: 'Point in Time Counts - FY 2018').first_or_create
      rs.update(weight: 0)
      r = Reports::Pit::Fy2018::Base.where(name: 'PIT - 2018').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::Pit::Fy2018::ByProject.where(name: 'PIT By Project - 2018').first_or_create
      r.update(weight: 2, report_results_summary: rs)

      rs = ReportResultsSummaries::Hic::Fy2017.where(name: 'Housing Inventory Counts - FY 2017').first_or_create
      rs.update(weight: 0)
      r = Reports::Hic::Fy2017::Base.where(name: 'HIC').first_or_create
      r.update(weight: 1, report_results_summary: rs)

      rs = ReportResultsSummaries::DataQuality::Fy2016.where(name: 'HUD Data Quality Report 2016').first_or_create
      rs.update(weight: 0)

      r = Reports::DataQuality::Fy2016::Q1.where(name: 'HUD Data Quality Report FY 2016 - Q1').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::DataQuality::Fy2016::Q2.where(name: 'HUD Data Quality Report FY 2016 - Q2').first_or_create
      r.update(weight: 2, report_results_summary: rs)
      r = Reports::DataQuality::Fy2016::Q3.where(name: 'HUD Data Quality Report FY 2016 - Q3').first_or_create
      r.update(weight: 3, report_results_summary: rs)
      r = Reports::DataQuality::Fy2016::Q4.where(name: 'HUD Data Quality Report FY 2016 - Q4').first_or_create
      r.update(weight: 4, report_results_summary: rs)
      r = Reports::DataQuality::Fy2016::Q5.where(name: 'HUD Data Quality Report FY 2016 - Q5').first_or_create
      r.update(weight: 5, report_results_summary: rs)
      r = Reports::DataQuality::Fy2016::Q6.where(name: 'HUD Data Quality Report FY 2016 - Q6').first_or_create
      r.update(weight: 6, report_results_summary: rs)
      r = Reports::DataQuality::Fy2016::Q7.where(name: 'HUD Data Quality Report FY 2016 - Q7').first_or_create
      r.update(weight: 7, report_results_summary: rs)


      rs = ReportResultsSummaries::DataQuality::Fy2016.where(name: 'HUD Data Quality Report 2017').first_or_create
      rs.update(weight: 0)

      r = Reports::DataQuality::Fy2017::Q1.where(name: 'HUD Data Quality Report FY 2017 - Q1').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::DataQuality::Fy2017::Q2.where(name: 'HUD Data Quality Report FY 2017 - Q2').first_or_create
      r.update(weight: 2, report_results_summary: rs)
      r = Reports::DataQuality::Fy2017::Q3.where(name: 'HUD Data Quality Report FY 2017 - Q3').first_or_create
      r.update(weight: 3, report_results_summary: rs)
      r = Reports::DataQuality::Fy2017::Q4.where(name: 'HUD Data Quality Report FY 2017 - Q4').first_or_create
      r.update(weight: 4, report_results_summary: rs)
      r = Reports::DataQuality::Fy2017::Q5.where(name: 'HUD Data Quality Report FY 2017 - Q5').first_or_create
      r.update(weight: 5, report_results_summary: rs)
      r = Reports::DataQuality::Fy2017::Q6.where(name: 'HUD Data Quality Report FY 2017 - Q6').first_or_create
      r.update(weight: 6, report_results_summary: rs)
      r = Reports::DataQuality::Fy2017::Q7.where(name: 'HUD Data Quality Report FY 2017 - Q7').first_or_create
      r.update(weight: 7, report_results_summary: rs)

      rs = ReportResultsSummaries::Lsa::Fy2018.where(name: 'LSA 2018').first_or_create
      rs.update(weight: 0)

      r = Reports::Lsa::Fy2018::All.where(name: 'Longitudinal System Analysis FY 2018').first_or_create
      .update(weight: 1, report_results_summary: rs)

  end
  desc "Remove all report types"
  task :clear => [:environment, "log:info_to_stdout"] do
    Report.all.map(&:destroy)
  end
end
