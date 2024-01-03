###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    xit 'Q4a' do
      question = 'Q4a'
      goals = goals(
        file_path: result_file_prefix + results_dir,
        question: question,
      )
      compare_columns(goal: goals, question: question, column_names: ['C', 'D'])
    end

    xit 'Q5a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q5a',
      )
    end

    xit 'Q6a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6a',
      )
    end

    xit 'Q7a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q7a',
      )
    end

    xit 'Q8a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8a',
      )
    end

    xit 'Q9a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9a',
      )
    end

    xit 'Q9b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9b',
      )
    end

    xit 'Q9c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9c',
      )
    end

    xit 'Q9d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9d',
      )
    end

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
