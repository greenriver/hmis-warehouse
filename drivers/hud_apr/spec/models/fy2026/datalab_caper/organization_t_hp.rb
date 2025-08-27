###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'datalab organization t hp caper', shared_context: :metadata do
  describe 'Datalab 2026 CAPER - Organization T - HP - 2' do
    let(:results_dir) { 'caper/organization_t_hp' }
    before(:all) do
      puts
      puts 'Running CAPER Organization T - HP - 2'
      generator = HudApr::Generators::Caper::Fy2026::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization T - HP - 2']).pluck(:id)
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
        skip: [
          'B17', # expected '1.0000' (1), got '0.0000' (0)
          'C17', # expected '1.0000' (1), got '0.0000' (0)
        ],
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6a',
        skip: [
          'C5', # expected '0.0000' (0), got '2.0000' (2)
          'E5', # expected '0.0000' (0), got '2.0000' (2)
          'F5', # expected '0.0000' (0.0000), got '0.0100' (0.0148)
        ],
      )
    end

    it 'Q6b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6b',
      )
    end

    it 'Q6c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6c',
      )
    end

    it 'Q6d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6d',
      )
    end

    it 'Q6e' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6e',
      )
    end

    it 'Q6f' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6f',
      )
    end

    it 'Q7a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q7a',
      )
    end

    it 'Q7b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q7b',
        skip: [
          'B3', # expected '13.0000' (13), got '22.0000' (22)
          'D3', # expected '8.0000' (8), got '17.0000' (17)
          'B5', # expected '1.0000' (1), got '17.0000' (17)
          'C5', # expected '1.0000' (1), got '7.0000' (7)
          'D5', # expected '0.0000' (0), got '10.0000' (10)
        ],
      )
    end

    it 'Q8a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8a',
      )
    end

    it 'Q8b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8b',
        skip: [
          'B3', # expected '5.0000' (5), got '8.0000' (8)
          'D3', # expected '2.0000' (2), got '5.0000' (5)
          'B5', # expected '0.0000' (0), got '8.0000' (8)
          'C5', # expected '0.0000' (0), got '5.0000' (5)
          'D5', # expected '0.0000' (0), got '3.0000' (3)
        ],
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

    # Removed in 2026
    # it 'Q10a' do
    #   compare_results(
    #     file_path: result_file_prefix + results_dir,
    #     question: 'Q10a',
    #   )
    # end

    # Removed in 2026
    # it 'Q10d' do
    #   compare_results(
    #     file_path: result_file_prefix + results_dir,
    #     question: 'Q10d',
    #   )
    # end

    it 'Q11' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q11',
      )
    end

    it 'Q12' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q12',
        skip: [
          'B5', # expected '2.0000' (2), got '0.0000' (0)
          'C5', # expected '1.0000' (1), got '0.0000' (0)
          'D5', # expected '1.0000' (1), got '0.0000' (0)
          'B8', # expected '84.0000' (84), got '101.0000' (101)
          'C8', # expected '37.0000' (37), got '42.0000' (42)
          'D8', # expected '47.0000' (47), got '59.0000' (59)
          'B26', # expected '17.0000' (17), got '0.0000' (0)
          'C26', # expected '5.0000' (5), got '0.0000' (0)
          'D26', # expected '12.0000' (12), got '0.0000' (0)
          'B33', # expected '0.0000' (0), got '2.0000' (2)
          'C33', # expected '0.0000' (0), got '1.0000' (1)
          'D33', # expected '0.0000' (0), got '1.0000' (1)
        ],
      )
    end

    it 'Q13a1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q13a1',
      )
    end

    it 'Q13b1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q13b1',
      )
    end

    it 'Q13c1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q13c1',
      )
    end

    it 'Q14a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q14a',
      )
    end

    it 'Q14b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q14b',
      )
    end

    it 'Q15' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q15',
      )
    end

    it 'Q16' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q16',
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q17',
      )
    end

    it 'Q19b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19b',
      )
    end

    it 'Q20a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q20a',
        skip: [
          'D2', # expected '27.0000' (27), got '28.0000' (28)
        ],
      )
    end

    it 'Q21' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q21',
      )
    end

    it 'Q22a2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22a2',
      )
    end

    it 'Q22c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22c',
      )
    end

    it 'Q22d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22d',
      )
    end

    it 'Q22e' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22e',
      )
    end

    it 'Q22f' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22f',
      )
    end

    it 'Q22g' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22g',
      )
    end

    it 'Q23c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q23c',
      )
    end

    it 'Q23d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q23d',
        skip: [
          'B5', # expected '0.0000' (0), got '4.0000' (4)
          'C5', # expected '0.0000' (0), got '2.0000' (2)
          'D5', # expected '0.0000' (0), got '2.0000' (2)
          'B6', # expected '0.0000' (0), got '5.0000' (5)
          'C6', # expected '0.0000' (0), got '1.0000' (1)
          'D6', # expected '0.0000' (0), got '4.0000' (4)
          'B13', # expected '0.0000' (0), got '9.0000' (9)
          'C13', # expected '0.0000' (0), got '3.0000' (3)
          'D13', # expected '0.0000' (0), got '6.0000' (6)
        ],
      )
    end

    it 'Q23e' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q23e',
        skip: [
          'I5', # expected '20.0000' (20), got '34.0000' (34)
          'J5', # expected '14.0000' (14), got '0.0000' (0)
          'I7', # expected '22.0000' (22), got '36.0000' (36)
          'J7', # expected '14.0000' (14), got '0.0000' (0)
        ],
      )
    end

    it 'Q24a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q24a',
        skip: [
          'B15', # expected '5.0000' (5), got '4.0000' (4)
          'C15', # expected '5.0000' (5), got '4.0000' (4)
        ],
      )
    end

    # Removed in 2026
    # it 'Q24d' do
    #   compare_results(
    #     file_path: result_file_prefix + results_dir,
    #     question: 'Q24d',
    #   )
    # end

    it 'Q25a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25a',
      )
    end

    it 'Q26b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26b',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab organization t hp caper', include_shared: true
end
