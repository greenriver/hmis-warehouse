###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'ce apr context FY2021', shared_context: :metadata do
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
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def race_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'DEFAULT-ES').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id])).update(
      shared_filter.merge(
        { 'races' => ['Asian'] },
      ),
    )
  end

  def age_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'DEFAULT-ES').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id])).update(
      shared_filter.merge(
        { 'age_ranges' => ['under_eighteen'] },
      ),
    )
  end

  def night_by_night_shelter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'NBN').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def ph
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'DEFAULT-PH').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def run(filter, question_name)
    generator = HudApr::Generators::CeApr::Fy2021::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: [question_name])).run!(email: false)
  end

  def default_setup_path
    'drivers/hud_apr/spec/fixtures/files/fy2021/default'
  end

  def default_ce_apr_setup_path
    'drivers/hud_apr/spec/fixtures/files/fy2021/default_ce_apr'
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def default_setup(file_path)
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!
    import_hmis_csv_fixture(file_path, version: 'AutoMigrate')
  end

  def cleanup
    # We dont need to do anything here currently
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'ce apr context FY2021', include_shared: true
end
