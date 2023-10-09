###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab th ce ce apr', shared_context: :metadata do
  describe 'Datalab 2023 CE APR - CE Only' do
    let(:results_dir) { 'ce_apr/ce' }
    before(:all) do
      generator = HudApr::Generators::CeApr::Fy2023::Generator
      project_ids = GrdaWarehouse::Hud::Project.all.pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q4a' do
      question = 'Q4a'
      goals = goals(
        file_path: result_file_prefix + results_dir,
        question: question,
      )
      compare_columns(goal: goals, question: question, column_names: ['C', 'D'])
    end

    it 'Q5a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q5a',
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6a',
      )
    end

    it 'Q7a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q7a',
      )
    end

    it 'Q8a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8a',
      )
    end

    it 'Q9a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9a',
      )
    end

    it 'Q9b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9b',
      )
    end

    it 'Q9c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9c',
      )
    end

    it 'Q9d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q9d',
      )
    end

    it 'Q10' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q10',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab th ce ce apr', include_shared: true
end
