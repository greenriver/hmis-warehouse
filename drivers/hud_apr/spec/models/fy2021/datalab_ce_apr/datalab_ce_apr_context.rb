###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do
  RSpec.configuration.fixpoints_path = 'drivers/hud_apr/spec/fixpoints'
end

RSpec.shared_context 'datalab ce apr context', shared_context: :metadata do
  def shared_filter
    {
      start: Date.parse('2020-10-01'),
      end: Date.parse('2021-09-30'),
      coc_codes: ['XX-500'],
      user_id: User.setup_system_user.id,
    }.freeze
  end

  def hmis_file_prefix
    'drivers/hud_apr/spec/fixtures/files/fy2021/datalab_hmis/*'
  end

  def result_file_prefix
    'drivers/hud_apr/spec/fixtures/files/fy2021/datalab_ce_apr/'
  end

  def ce_and_es_filter
    project_ids = GrdaWarehouse::Hud::Project.where(ProjectID: ['942', '240']).pluck(:id)
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: project_ids))
  end

  def ce_only_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: '942').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def setup
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!

    warehouse = GrdaWarehouseBase.connection

    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    if Fixpoint.exists? :datalab_2021_app
      restore_fixpoint :datalab_2021_app
      restore_fixpoint :datalab_2021_warehouse, connection: warehouse
    else
      files = Dir.glob(hmis_file_prefix).select { |f| File.directory? f }
      files.each.with_index do |file_path, i|
        puts "*** #{file_path} ***"
        import_hmis_csv_fixture(file_path, run_jobs: i == files.count - 1, version: 'AutoMigrate')
      end
      store_fixpoint :datalab_2021_app
      store_fixpoint :datalab_2021_warehouse, connection: warehouse
    end
  end

  def run(filter)
    generator = HudApr::Generators::CeApr::Fy2021::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: generator.questions.keys)).run!(email: false)
  end

  def cleanup
    # We don't need to do anything here currently
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  require_relative '../table_comparisons'
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab ce apr context', include_shared: true
end
