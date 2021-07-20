###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do |config|
  RSpec.configuration.fixpoints_path = 'drivers/hud_apr/spec/fixpoints'
end

RSpec.shared_context 'caper context', shared_context: :metadata do
  def shared_filter
    {
      start: Date.parse('2019-01-01'),
      end: Date.parse('2019-12-31'),
      coc_codes: ['XX-500'],
      user_id: User.setup_system_user.id,
    }.freeze
  end

  def default_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'DEFAULT-ES').id
    HudApr::Filters::AprFilter.new(shared_filter.merge(project_ids: [project_id]))
  end

  def night_by_night_shelter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'NBN').id
    HudApr::Filters::AprFilter.new(shared_filter.merge(project_ids: [project_id]))
  end

  def run(filter, question_name)
    generator = HudApr::Generators::Caper::Fy2020::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: [question_name])).run!
  end

  def default_setup_path
    'drivers/hud_apr/spec/fixtures/files/fy2020/default'
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def default_setup
    warehouse = GrdaWarehouseBase.connection

    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    if Fixpoint.exists? :hud_hmis_export_app
      GrdaWarehouse::Utility.clear!
      restore_fixpoint :hud_hmis_export_app
      restore_fixpoint :hud_hmis_export_warehouse, connection: warehouse
    else
      setup(default_setup_path)
      store_fixpoint :hud_hmis_export_app
      store_fixpoint :hud_hmis_export_warehouse, connection: warehouse
    end
  end

  def setup(file_path)
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!
    import_hmis_csv_fixture(file_path)
  end

  def cleanup
    # We dont need to do anything here currently
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'caper context', include_shared: true
end
