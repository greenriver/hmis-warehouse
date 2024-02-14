###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab systemwide ce apr', shared_context: :metadata do
  describe 'Datalab 2024 CE APR - SystemWide' do
    let(:results_dir) { 'ce_apr/systemwide' }
    before(:all) do
      generator = HudApr::Generators::CeApr::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.all.pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    # TODO: make this align
    xit 'Q4a' do
      # question = 'Q4a'
      # goals = goals(
      #   file_path: result_file_prefix + results_dir,
      #   question: question,
      #   external_column_header: false,
      # )
      # compare_columns(goal: goals, question: question, column_names: ['C', 'D'])
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q4a',
      )
    end

    # TODO: Off by a few
    xit 'Q5a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q5a',
      )
    end

    # TODO: Off by a few
    xit 'Q6a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6a',
      )
    end

    # TODO: Off by a few
    xit 'Q7a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q7a',
      )
    end

    # TODO: Off by a few
    xit 'Q8a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8a',
      )
    end

    # TODO: Off by a few
    xit 'Q9a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9a',
      )
    end

    # TODO: Off by a few
    xit 'Q9b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9b',
      )
    end

    # TODO: Off by a few
    xit 'Q9c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9c',
      )
    end

    # TODO: Off by a few
    xit 'Q9d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9d',
      )
    end

    # TODO: Off by a few
    xit 'Q10' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q10',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab systemwide ce apr', include_shared: true
end
