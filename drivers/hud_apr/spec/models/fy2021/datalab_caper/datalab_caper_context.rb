###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do
  RSpec.configuration.fixpoints_path = 'drivers/hud_apr/spec/fixpoints'
end

RSpec.shared_context 'datalab caper context', shared_context: :metadata do
  def shared_filter
    {
      start: Date.parse('2020-10-01'),
      end: Date.parse('2021-09-30'),
      coc_codes: ['XX-500'],
      user_id: User.setup_system_user.id,
    }.freeze
  end

  def project_type_filter(project_type)
    project_ids = GrdaWarehouse::Hud::Project.where(ProjectType: project_type).pluck(:id)
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: project_ids))
  end

  def rrh_1_filter # The RRH CAPER is not run for all the RRH projects in the datasource
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: '808').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def es_ee_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: '240').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def es_nbm_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: '882').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def hmis_file_prefix
    'drivers/hud_apr/spec/fixtures/files/fy2021/datalab_hmis/*'
  end

  def result_file_prefix
    'drivers/hud_apr/spec/fixtures/files/fy2021/datalab_caper/'
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
      Dir.glob(hmis_file_prefix).select { |f| File.directory? f }.each do |file_path|
        puts "*** #{file_path} ***"
        import_hmis_csv_fixture(file_path, version: 'AutoMigrate')
      end
      store_fixpoint :datalab_2021_app
      store_fixpoint :datalab_2021_warehouse, connection: warehouse
    end
  end

  def run(filter)
    generator = HudApr::Generators::Caper::Fy2021::Generator
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
  rspec.include_context 'datalab caper context', include_shared: true
end
