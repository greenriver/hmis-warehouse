###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab th ce ce apr', shared_context: :metadata do
  describe 'Datalab 2021 CE APR - CE Only' do
    before(:all) do
      generator = HudApr::Generators::CeApr::Fy2021::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['DataLab - Coordinated Entry']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q4a' do
      question = 'Q4a'
      goals = goals(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: question,
      )
      compare_columns(goal: goals, question: question, column_names: ['C', 'D'])
    end

    it 'Q5a' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q5a',
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q6a',
      )
    end

    it 'Q7a' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q7a',
      )
    end

    it 'Q8a' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q8a',
      )
    end

    it 'Q9a' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q9a',
      )
    end

    it 'Q9b' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q9b',
      )
    end

    it 'Q9c' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q9c',
      )
    end

    it 'Q9d' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q9d',
        # skip: [
        #   'B23', # Rounding difference
        # ],
      )
    end

    it 'Q10' do
      compare_results(
        file_path: result_file_prefix + 'ce_apr/ce',
        question: 'Q10',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab th ce ce apr', include_shared: true
end
