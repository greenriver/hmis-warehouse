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

  def goals(file_path:, question:)
    csv_file = File.join(file_path, question + '.csv')
    CSV.read(csv_file)
  end

  # Compare the contents of columns ignoring row order but preserving the column relationships.
  def compare_columns(goal:, question:, column_names:)
    results_metadata = report_result.answer(question: question).metadata
    column_names = Array.wrap(column_names)

    results_row = (results_metadata['first_row'] .. results_metadata['last_row']).map do |row_number|
      row = []
      column_names.each do |column_name|
        cell_name = column_name + row_number.to_s
        row << normalize(report_result.answer(question: question, cell: cell_name).summary)
      end
      row
    end

    column_labels = ('A'..'Z').to_a.freeze
    goal_row = (results_metadata['first_row'] .. results_metadata['last_row']).map do |row_number|
      row = []
      column_names.each do |column_name|
        row << normalize(goal[row_number - 1][column_labels.find_index(column_name)])
      end
      row
    end

    aggregate_failures 'comparing column values' do
      expect(results_row.size).to eq(goal_row.size)
      expect(results_row).to match_array(goal_row)
    end
  end

  def compare_results(goal: nil, file_path:, question:, skip: [])
    column_labels = ('A'..'Z').to_a
    goal ||= goals(file_path: file_path, question: question)

    aggregate_failures 'comparing cells' do
      results_metadata = report_result.answer(question: question).metadata
      (results_metadata['first_row'] .. results_metadata['last_row']).each do |row_number|
        (results_metadata['first_column'] .. results_metadata['last_column']).each do |column_name|
          cell_name = column_name + row_number.to_s
          next if cell_name.in?(skip)

          column_index = column_labels.find_index(column_name)
          expected = normalize(goal[row_number - 1].try(:[], column_index))
          actual = normalize(report_result.answer(question: question, cell: cell_name).summary)

          expect(actual).to eq(expected), "#{cell_name}: expected '#{expected}', got '#{actual}'"
        end
      end
    end
  end

  def normalize(value)
    value = value&.to_s&.strip
    value = '0' if normalize_zero?(value) # Treat all zeros as '0'
    value = '0' if value.blank? # Treat 0 and blank as the same for comparison
    value = value[1..] if money?(value) # Remove dollar signs

    value
  end

  def normalize_zero?(value)
    /^[0\.]+$/.match?(value)
  end

  def money?(value)
    /^\$[0-9\.]+$/.match?(value)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab context', include_shared: true
end
