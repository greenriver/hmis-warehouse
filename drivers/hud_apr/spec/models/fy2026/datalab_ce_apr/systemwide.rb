###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'datalab systemwide ce apr', shared_context: :metadata do
  describe 'Datalab 2026 CE APR - SystemWide' do
    let(:results_dir) { 'ce_apr/systemwide' }
    before(:all) do
      puts
      puts 'Running CE APR SystemWide'
      generator = HudApr::Generators::CeApr::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.all.pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q4a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q4a',
      )
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

    # TODO: Off by a few
    xit 'Q8a' do
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
  rspec.include_context 'datalab systemwide ce apr', include_shared: true
end
