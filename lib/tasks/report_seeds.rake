# Add a bunch a reports
# NOTE: these are now usually injected by drivers, if you aren't seeing the report
# in your development environment, make sure you restart your webserver.
namespace :reports do
  desc 'Load Available Report Types'
  task seed: [:environment, 'log:info_to_stdout'] do
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
    removed += spm_2018 if Date.current > '2020-10-01'.to_date || ! ReportResult.joins(:report).merge(Reports::SystemPerformance::Fy2018::MeasureOne.where(type: spm_2018)).exists?
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
    removed += spm_2019 if Date.current > '2021-07-01'.to_date || Rails.env.development? || ! ReportResult.joins(:report).merge(Reports::SystemPerformance::Fy2018::MeasureOne.where(type: spm_2018)).exists?
    Report.where(type: removed).update_all(enabled: false)

    rs = ReportResultsSummaries::Pit::Fy2018.where(name: 'Point in Time Counts - FY 2018').first_or_create
    rs.update(weight: 0)
    r = Reports::Pit::Fy2018::Base.where(name: 'PIT - 2018').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)
    r = Reports::Pit::Fy2018::ByProject.where(name: 'PIT By Project - 2018').first_or_create
    r.update(weight: 2, report_results_summary: rs, enabled: true)

    rs = ReportResultsSummaries::Hic::Fy2019.where(name: 'Housing Inventory Counts - FY 2019').first_or_create
    rs.update(weight: 0)

    r = Reports::Hic::Fy2019::Base.where(name: 'HIC').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)

    rs = ReportResultsSummaries::Lsa::Fy2018.where(name: 'LSA 2018').first_or_create
    rs.update(weight: 0)
    r = Reports::Lsa::Fy2018::All.where(name: 'Longitudinal System Analysis FY 2018').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)

    rs = ReportResultsSummaries::Lsa::Fy2019.where(name: 'LSA 2019').first_or_create
    rs.update(weight: 0)
    r = Reports::Lsa::Fy2019::All.where(name: 'Longitudinal System Analysis FY 2019').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)

    rs = ReportResultsSummaries::Lsa::Fy2021.where(name: 'LSA 2021').first_or_create
    rs.update(weight: 0)
    r = Reports::Lsa::Fy2021::All.where(name: 'Longitudinal System Analysis FY 2021').first_or_create
    r.update(weight: 1, report_results_summary: rs, enabled: true)
  end

  desc 'Remove all report types'
  task clear: [:environment, 'log:info_to_stdout'] do
    Report.all.map(&:destroy)
  end
end
