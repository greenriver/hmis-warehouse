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
      start: Date.parse('2022-01-01'),
      end: Date.parse('2022-12-31'),
      project_type_codes: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.keys,
      coc_codes: ['XX-500', 'XX-501'],
    }
  end

  def run!(filter)
    HomelessSummaryReport::Report.new(user_id: User.setup_system_user.id, filter: filter).run_and_save!
  end

  def report_result
    @report_result ||= HomelessSummaryReport::Report.last
  end

  def result(field, demographics)
    HomelessSummaryReport::Result.find_by(field: field, detail_link_slug: demographics, calculation: :count, report_id: report_result.id).value
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
