###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'report context', shared_context: :metadata do
  def default_setup_path
    'drivers/homeless_summary_report/spec/fixtures/files/default'
  end

  def default_filter
    {
    }
  end

  def run!(filter)
    HomelessSummaryReport::Report.new(user_id: User.setup_system_user.id, filter: filter).run_and_save!
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def setup(file_path)
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
    import_hmis_csv_fixture(file_path, version: 'AutoMigrate')
  end

  def cleanup
    # We don't need to do anything here currently
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'report context', include_shared: true
end
