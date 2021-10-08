###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do
  RSpec.configuration.fixpoints_path = 'drivers/hud_apr/spec/fixpoints'
end

RSpec.shared_context 'datalab context', shared_context: :metadata do
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
    'drivers/hud_apr/spec/fixtures/files/fy2021/datalab_apr/'
  end

  def project_type_filter(project_type)
    project_ids = GrdaWarehouse::Hud::Project.where(ProjectType: project_type).pluck(:id)
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: project_ids))
  end

  def rrh_1_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: '808').id
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
      Dir.glob(hmis_file_prefix).select { |f| File.directory? f }.each do |file_path|
        puts "*** #{file_path} ***"
        import_hmis_csv_fixture(file_path, version: 'AutoMigrate')
      end
      store_fixpoint :datalab_2021_app
      store_fixpoint :datalab_2021_warehouse, connection: warehouse
    end
  end

  def run(filter)
    generator = HudApr::Generators::Apr::Fy2021::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: generator.questions.keys)).run!(email: false)
  end

  def cleanup
    # We don't need to do anything here currently
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def compare_results(file_path:, question:, skip: [])
    column_labels = ('A'..'Z').to_a
    csv_file = File.join(file_path, question + '.csv')
    goal = CSV.read(csv_file)

    aggregate_failures 'comparing cells' do
      results_metadata = report_result.answer(question: question).metadata
      (results_metadata['first_row'] .. results_metadata['last_row']).each do |row_number|
        (results_metadata['first_column'] .. results_metadata['last_column']).each do |column_name|
          cell_name = column_name + row_number.to_s
          next if cell_name.in?(skip)

          column_index = column_labels.find_index(column_name)
          expected = goal[row_number - 1].try(:[], column_index)&.to_s&.strip
          actual = report_result.answer(question: question, cell: cell_name).summary.to_s.strip

          actual = '0' if normalize_zero?(actual) # Treat all zeros as '0'
          expected = '0' if normalize_zero?(expected)
          actual = '0' if actual.blank? # Treat 0 and blank as the same for comparison
          expected = '0' if expected.blank?
          expected = expected[1..] if expected[0] == '$'

          expect(actual).to eq(expected), "#{cell_name}: expected '#{expected}', got '#{actual}'"
        end
      end
    end
  end

  def normalize_zero?(value)
    /^[0\.]+$/.match?(value)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab context', include_shared: true
end
