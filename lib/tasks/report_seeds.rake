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

      rs = ReportResultsSummaries::SystemPerformance::Fy2016.where(name: 'HUD System Performance FY 2016').first_or_create
      rs.update(weight: 0)

      r = Reports::SystemPerformance::Fy2016::MeasureOne.where(name: 'HUD System Performance FY 2016 - Measure 1').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2016::MeasureTwo.where(name: 'HUD System Performance FY 2016 - Measure 2').first_or_create
      r.update(weight: 2, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2016::MeasureThree.where(name: 'HUD System Performance FY 2016 - Measure 3').first_or_create
      r.update(weight: 3, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2016::MeasureFour.where(name: 'HUD System Performance FY 2016 - Measure 4').first_or_create
      r.update(weight: 4, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2016::MeasureFive.where(name: 'HUD System Performance FY 2016 - Measure 5').first_or_create
      r.update(weight: 5, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2016::MeasureSix.where(name: 'HUD System Performance FY 2016 - Measure 6').first_or_create
      r.update(weight: 6, report_results_summary: rs)
      r = Reports::SystemPerformance::Fy2016::MeasureSeven.where(name: 'HUD System Performance FY 2016 - Measure 7').first_or_create
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

      rs = ReportResultsSummaries::CAPER::Fy2017.where(name: 'Consolidated Annual Performance and Evaluation Report 2017').first_or_create
      rs.update(weight: 0)

      r = Reports::CAPER::Fy2017::Q4a.where(name: 'HUD ESG-CAPER 2017 - Q4a').first_or_create
      r.update(weight: 1, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q5a.where(name: 'HUD ESG-CAPER 2017 - Q5a').first_or_create
      r.update(weight: 2, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q6a.where(name: 'HUD ESG-CAPER 2017 - Q6a').first_or_create
      r.update(weight: 3, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q6b.where(name: 'HUD ESG-CAPER 2017 - Q6b').first_or_create
      r.update(weight: 4, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q6c.where(name: 'HUD ESG-CAPER 2017 - Q6c').first_or_create
      r.update(weight: 5, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q6d.where(name: 'HUD ESG-CAPER 2017 - Q6d').first_or_create
      r.update(weight: 6, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q6e.where(name: 'HUD ESG-CAPER 2017 - Q6e').first_or_create
      r.update(weight: 7, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q6f.where(name: 'HUD ESG-CAPER 2017 - Q6f').first_or_create
      r.update(weight: 8, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q7a.where(name: 'HUD ESG-CAPER 2017 - Q7a').first_or_create
      r.update(weight: 9, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q8a.where(name: 'HUD ESG-CAPER 2017 - Q8a').first_or_create
      r.update(weight: 10, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q8b.where(name: 'HUD ESG-CAPER 2017 - Q8b').first_or_create
      r.update(weight: 11, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q9a.where(name: 'HUD ESG-CAPER 2017 - Q9a').first_or_create
      r.update(weight: 12, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q9b.where(name: 'HUD ESG-CAPER 2017 - Q9b').first_or_create
      r.update(weight: 13, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q10a.where(name: 'HUD ESG-CAPER 2017 - Q10a').first_or_create
      r.update(weight: 14, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q10b.where(name: 'HUD ESG-CAPER 2017 - Q10b').first_or_create
      r.update(weight: 15, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q10c.where(name: 'HUD ESG-CAPER 2017 - Q10c').first_or_create
      r.update(weight: 16, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q11.where(name: 'HUD ESG-CAPER 2017 - Q11').first_or_create
      r.update(weight: 17, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q12a.where(name: 'HUD ESG-CAPER 2017 - Q12a').first_or_create
      r.update(weight: 18, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q12b.where(name: 'HUD ESG-CAPER 2017 - Q12b').first_or_create
      r.update(weight: 19, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q13a1.where(name: 'HUD ESG-CAPER 2017 - Q13a1').first_or_create
      r.update(weight: 20, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q13b1.where(name: 'HUD ESG-CAPER 2017 - Q13b1').first_or_create
      r.update(weight: 21, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q13c1.where(name: 'HUD ESG-CAPER 2017 - Q13c1').first_or_create
      r.update(weight: 22, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q14a.where(name: 'HUD ESG-CAPER 2017 - Q14a').first_or_create
      r.update(weight: 23, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q14b.where(name: 'HUD ESG-CAPER 2017 - Q14b').first_or_create
      r.update(weight: 24, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q15.where(name: 'HUD ESG-CAPER 2017 - Q15').first_or_create
      r.update(weight: 25, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q20a.where(name: 'HUD ESG-CAPER 2017 - Q20a').first_or_create
      r.update(weight: 26, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q21.where(name: 'HUD ESG-CAPER 2017 - Q21').first_or_create
      r.update(weight: 27, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q22c.where(name: 'HUD ESG-CAPER 2017 - Q22c').first_or_create
      r.update(weight: 28, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q23a.where(name: 'HUD ESG-CAPER 2017 - Q23a').first_or_create
      r.update(weight: 29, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q23b.where(name: 'HUD ESG-CAPER 2017 - Q23b').first_or_create
      r.update(weight: 30, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q23c.where(name: 'HUD ESG-CAPER 2017 - Q23c').first_or_create
      r.update(weight: 31, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q24.where(name: 'HUD ESG-CAPER 2017 - Q24').first_or_create
      r.update(weight: 32, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q25a.where(name: 'HUD ESG-CAPER 2017 - Q25a').first_or_create
      r.update(weight: 33, report_results_summary: rs)
      r = Reports::CAPER::Fy2017::Q26b.where(name: 'HUD ESG-CAPER 2017 - Q26b').first_or_create
      r.update(weight: 34, report_results_summary: rs)
end
  desc "Remove all report types"
  task :clear => [:environment, "log:info_to_stdout"] do
    Report.all.map(&:destroy)
  end
end
