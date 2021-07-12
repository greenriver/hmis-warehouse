# Add a bunch a reports
namespace :reports do
  desc "Load Available Report Types"
  task :seed => [:environment, "log:info_to_stdout"] do
    # Removed
    removed = [
      'Reports::SystemPerformance::Fy2015::MeasureOne',
      'Reports::SystemPerformance::Fy2015::MeasureTwo',
      'Reports::SystemPerformance::Fy2015::MeasureThree',
      'Reports::SystemPerformance::Fy2015::MeasureFour',
      'Reports::SystemPerformance::Fy2015::MeasureFive',
      'Reports::SystemPerformance::Fy2015::MeasureSix',
      'Reports::SystemPerformance::Fy2015::MeasureSeven',
      'Reports::SystemPerformance::Fy2016::MeasureOne',
      'Reports::SystemPerformance::Fy2016::MeasureTwo',
      'Reports::SystemPerformance::Fy2016::MeasureThree',
      'Reports::SystemPerformance::Fy2016::MeasureFour',
      'Reports::SystemPerformance::Fy2016::MeasureFive',
      'Reports::SystemPerformance::Fy2016::MeasureSix',
      'Reports::SystemPerformance::Fy2016::MeasureSeven',
      'Reports::SystemPerformance::Fy2017::MeasureOne',
      'Reports::SystemPerformance::Fy2017::MeasureTwo',
      'Reports::SystemPerformance::Fy2017::MeasureThree',
      'Reports::SystemPerformance::Fy2017::MeasureFour',
      'Reports::SystemPerformance::Fy2017::MeasureFive',
      'Reports::SystemPerformance::Fy2017::MeasureSix',
      'Reports::SystemPerformance::Fy2017::MeasureSeven',
      'Reports::Ahar::Fy2016::Base',
      'Reports::Ahar::Fy2016::Veteran',
      'Reports::Ahar::Fy2016::ByProject',
      'Reports::Ahar::Fy2016::ByDataSource',
      'Reports::Ahar::Fy2017::Base',
      'Reports::Ahar::Fy2017::Veteran',
      'Reports::Ahar::Fy2017::ByProject',
      'Reports::Ahar::Fy2017::ByDataSource',
      'Reports::Pit::Fy2017::Base',
      'Reports::Pit::Fy2017::ByProject',
      'Reports::Hic::Fy2017::Base',
      'Reports::DataQuality::Fy2016::Q1',
      'Reports::DataQuality::Fy2016::Q2',
      'Reports::DataQuality::Fy2016::Q3',
      'Reports::DataQuality::Fy2016::Q4',
      'Reports::DataQuality::Fy2016::Q5',
      'Reports::DataQuality::Fy2016::Q6',
      'Reports::DataQuality::Fy2016::Q7',
      'Reports::DataQuality::Fy2017::Q1',
      'Reports::DataQuality::Fy2017::Q2',
      'Reports::DataQuality::Fy2017::Q3',
      'Reports::DataQuality::Fy2017::Q4',
      'Reports::DataQuality::Fy2017::Q5',
      'Reports::DataQuality::Fy2017::Q6',
      'Reports::DataQuality::Fy2017::Q7',
      # 'Reports::Lsa::Fy2018::All',
    ]
    # SPM 2018 should be removed after 10/1/2020 to allow for comparisons
    # If we've never run it, go ahead and remove it.
    spm_2018 = [
      'Reports::SystemPerformance::Fy2018::MeasureOne',
      'Reports::SystemPerformance::Fy2018::MeasureTwo',
      'Reports::SystemPerformance::Fy2018::MeasureThree',
      'Reports::SystemPerformance::Fy2018::MeasureFour',
      'Reports::SystemPerformance::Fy2018::MeasureFive',
      'Reports::SystemPerformance::Fy2018::MeasureSix',
      'Reports::SystemPerformance::Fy2018::MeasureSeven',
    ]
    if Date.current > '2020-10-01'.to_date || ! ReportResult.joins(:report).merge(Reports::SystemPerformance::Fy2018::MeasureOne.where(type: spm_2018)).exists?
      removed += spm_2018
    end
    # # SPM 2019 should be removed after 10/1/2021 to allow for comparisons
    # # If we've never run it, go ahead and remove it.
    # Backdated this to 7/1/2021 as having two versions of the SPM is confusing folks
    spm_2019 = [
      'Reports::SystemPerformance::Fy2019::MeasureOne',
      'Reports::SystemPerformance::Fy2019::MeasureTwo',
      'Reports::SystemPerformance::Fy2019::MeasureThree',
      'Reports::SystemPerformance::Fy2019::MeasureFour',
      'Reports::SystemPerformance::Fy2019::MeasureFive',
      'Reports::SystemPerformance::Fy2019::MeasureSix',
      'Reports::SystemPerformance::Fy2019::MeasureSeven',
    ]
    if Date.current > '2021-07-01'.to_date || Rails.env.development? || ! ReportResult.joins(:report).merge(Reports::SystemPerformance::Fy2018::MeasureOne.where(type: spm_2018)).exists?
      removed += spm_2019
    end
    Report.where(type: removed).update_all(enabled: false)

    # Summary
    # rs = ReportResultsSummaries::SystemPerformance::Fy2015.where(name: 'HUD System Performance FY 2015').first_or_create
    # rs.update(weight: 0)

    # r = Reports::SystemPerformance::Fy2015::MeasureOne.where(name: 'HUD System Performance FY 2015 - Measure 1').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2015::MeasureTwo.where(name: 'HUD System Performance FY 2015 - Measure 2').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2015::MeasureThree.where(name: 'HUD System Performance FY 2015 - Measure 3').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2015::MeasureFour.where(name: 'HUD System Performance FY 2015 - Measure 4').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2015::MeasureFive.where(name: 'HUD System Performance FY 2015 - Measure 5').first_or_create
    # r.update(weight: 5, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2015::MeasureSix.where(name: 'HUD System Performance FY 2015 - Measure 6').first_or_create
    # r.update(weight: 6, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2015::MeasureSeven.where(name: 'HUD System Performance FY 2015 - Measure 7').first_or_create
    # r.update(weight: 7, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::SystemPerformance::Fy2016.where(name: 'HUD System Performance FY 2016').first_or_create
    # rs.update(weight: 0)

    # r = Reports::SystemPerformance::Fy2016::MeasureOne.where(name: 'HUD System Performance FY 2016 - Measure 1').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2016::MeasureTwo.where(name: 'HUD System Performance FY 2016 - Measure 2').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2016::MeasureThree.where(name: 'HUD System Performance FY 2016 - Measure 3').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2016::MeasureFour.where(name: 'HUD System Performance FY 2016 - Measure 4').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2016::MeasureFive.where(name: 'HUD System Performance FY 2016 - Measure 5').first_or_create
    # r.update(weight: 5, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2016::MeasureSix.where(name: 'HUD System Performance FY 2016 - Measure 6').first_or_create
    # r.update(weight: 6, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2016::MeasureSeven.where(name: 'HUD System Performance FY 2016 - Measure 7').first_or_create
    # r.update(weight: 7, report_results_summary: rs, enabled: true)
    #
    # rs = ReportResultsSummaries::SystemPerformance::Fy2017.where(name: 'HUD System Performance FY 2017').first_or_create
    # rs.update(weight: 0)
    #
    # r = Reports::SystemPerformance::Fy2017::MeasureOne.where(name: 'HUD System Performance FY 2017 - Measure 1').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2017::MeasureTwo.where(name: 'HUD System Performance FY 2017 - Measure 2').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2017::MeasureThree.where(name: 'HUD System Performance FY 2017 - Measure 3').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2017::MeasureFour.where(name: 'HUD System Performance FY 2017 - Measure 4').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2017::MeasureFive.where(name: 'HUD System Performance FY 2017 - Measure 5').first_or_create
    # r.update(weight: 5, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2017::MeasureSix.where(name: 'HUD System Performance FY 2017 - Measure 6').first_or_create
    # r.update(weight: 6, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2017::MeasureSeven.where(name: 'HUD System Performance FY 2017 - Measure 7').first_or_create
    # r.update(weight: 7, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::SystemPerformance::Fy2018.where(name: 'HUD System Performance FY 2018').first_or_create
    # rs.update(weight: 0)
    # #
    # r = Reports::SystemPerformance::Fy2018::MeasureOne.where(name: 'HUD System Performance FY 2018 - Measure 1').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2018::MeasureTwo.where(name: 'HUD System Performance FY 2018 - Measure 2').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2018::MeasureThree.where(name: 'HUD System Performance FY 2018 - Measure 3').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2018::MeasureFour.where(name: 'HUD System Performance FY 2018 - Measure 4').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2018::MeasureFive.where(name: 'HUD System Performance FY 2018 - Measure 5').first_or_create
    # r.update(weight: 5, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2018::MeasureSix.where(name: 'HUD System Performance FY 2018 - Measure 6').first_or_create
    # r.update(weight: 6, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2018::MeasureSeven.where(name: 'HUD System Performance FY 2018 - Measure 7').first_or_create
    # r.update(weight: 7, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::SystemPerformance::Fy2019.where(name: 'HUD System Performance FY 2019').first_or_create
    # rs.update(weight: 0)

    # r = Reports::SystemPerformance::Fy2019::MeasureOne.where(name: 'HUD System Performance FY 2019 - Measure 1').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2019::MeasureTwo.where(name: 'HUD System Performance FY 2019 - Measure 2').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2019::MeasureThree.where(name: 'HUD System Performance FY 2019 - Measure 3').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2019::MeasureFour.where(name: 'HUD System Performance FY 2019 - Measure 4').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2019::MeasureFive.where(name: 'HUD System Performance FY 2019 - Measure 5').first_or_create
    # r.update(weight: 5, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2019::MeasureSix.where(name: 'HUD System Performance FY 2019 - Measure 6').first_or_create
    # r.update(weight: 6, report_results_summary: rs, enabled: true)
    # r = Reports::SystemPerformance::Fy2019::MeasureSeven.where(name: 'HUD System Performance FY 2019 - Measure 7').first_or_create
    # r.update(weight: 7, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::Ahar::Fy2016.where(name: 'Annual Homeless Assessment Report - FY 2016').first_or_create
    # rs.update(weight: 0)
    # r = Reports::Ahar::Fy2016::Base.where(name: 'AHAR').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::Ahar::Fy2016::Veteran.where(name: 'Veteran AHAR').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::Ahar::Fy2016::ByProject.where(name: 'AHAR By Project').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::Ahar::Fy2016::ByDataSource.where(name: 'AHAR By Data Source').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::Ahar::Fy2017.where(name: 'Annual Homeless Assessment Report - FY 2017').first_or_create
    # rs.update(weight: 0)
    # r = Reports::Ahar::Fy2017::Base.where(name: 'AHAR - 2017').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::Ahar::Fy2017::Veteran.where(name: 'Veteran AHAR - 2017').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::Ahar::Fy2017::ByProject.where(name: 'AHAR By Project - 2017').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::Ahar::Fy2017::ByDataSource.where(name: 'AHAR By Data Source - 2017').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::Pit::Fy2017.where(name: 'Point in Time Counts - FY 2017').first_or_create
    # rs.update(weight: 0)
    # r = Reports::Pit::Fy2017::Base.where(name: 'PIT').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::Pit::Fy2017::ByProject.where(name: 'PIT By Project').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)

    rs = ReportResultsSummaries::Pit::Fy2018.where(name: 'Point in Time Counts - FY 2018').first_or_create
    rs.update(weight: 0)
    r = Reports::Pit::Fy2018::Base.where(name: 'PIT - 2018').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)
    r = Reports::Pit::Fy2018::ByProject.where(name: 'PIT By Project - 2018').first_or_create
    r.update(weight: 2, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::Hic::Fy2017.where(name: 'Housing Inventory Counts - FY 2017').first_or_create
    # rs.update(weight: 0)
    # r = Reports::Hic::Fy2017::Base.where(name: 'HIC').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)

    rs = ReportResultsSummaries::Hic::Fy2019.where(name: 'Housing Inventory Counts - FY 2019').first_or_create
    rs.update(weight: 0)

    r = Reports::Hic::Fy2019::Base.where(name: 'HIC').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::DataQuality::Fy2016.where(name: 'HUD Data Quality Report 2016').first_or_create
    # rs.update(weight: 0)

    # r = Reports::DataQuality::Fy2016::Q1.where(name: 'HUD Data Quality Report FY 2016 - Q1').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2016::Q2.where(name: 'HUD Data Quality Report FY 2016 - Q2').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2016::Q3.where(name: 'HUD Data Quality Report FY 2016 - Q3').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2016::Q4.where(name: 'HUD Data Quality Report FY 2016 - Q4').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2016::Q5.where(name: 'HUD Data Quality Report FY 2016 - Q5').first_or_create
    # r.update(weight: 5, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2016::Q6.where(name: 'HUD Data Quality Report FY 2016 - Q6').first_or_create
    # r.update(weight: 6, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2016::Q7.where(name: 'HUD Data Quality Report FY 2016 - Q7').first_or_create
    # r.update(weight: 7, report_results_summary: rs, enabled: true)

    # rs = ReportResultsSummaries::DataQuality::Fy2017.where(name: 'HUD Data Quality Report 2017').first_or_create
    # rs.update(weight: 0)
    #
    # r = Reports::DataQuality::Fy2017::Q1.where(name: 'HUD Data Quality Report FY 2017 - Q1').first_or_create
    # r.update(weight: 1, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2017::Q2.where(name: 'HUD Data Quality Report FY 2017 - Q2').first_or_create
    # r.update(weight: 2, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2017::Q3.where(name: 'HUD Data Quality Report FY 2017 - Q3').first_or_create
    # r.update(weight: 3, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2017::Q4.where(name: 'HUD Data Quality Report FY 2017 - Q4').first_or_create
    # r.update(weight: 4, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2017::Q5.where(name: 'HUD Data Quality Report FY 2017 - Q5').first_or_create
    # r.update(weight: 5, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2017::Q6.where(name: 'HUD Data Quality Report FY 2017 - Q6').first_or_create
    # r.update(weight: 6, report_results_summary: rs, enabled: true)
    # r = Reports::DataQuality::Fy2017::Q7.where(name: 'HUD Data Quality Report FY 2017 - Q7').first_or_create
    # r.update(weight: 7, report_results_summary: rs, enabled: true)

    rs = ReportResultsSummaries::Lsa::Fy2018.where(name: 'LSA 2018').first_or_create
    rs.update(weight: 0)
    r = Reports::Lsa::Fy2018::All.where(name: 'Longitudinal System Analysis FY 2018').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)

    rs = ReportResultsSummaries::Lsa::Fy2019.where(name: 'LSA 2019').first_or_create
    rs.update(weight: 0)
    r = Reports::Lsa::Fy2019::All.where(name: 'Longitudinal System Analysis FY 2019').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)

  end
  desc "Remove all report types"
  task :clear => [:environment, "log:info_to_stdout"] do
    Report.all.map(&:destroy)
  end
end
