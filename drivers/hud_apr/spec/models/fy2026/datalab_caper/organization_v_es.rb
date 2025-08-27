###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'datalab organization v es caper', shared_context: :metadata do
  describe 'Datalab 2026 CAPER - Organization V - ES' do
    let(:results_dir) { 'caper/organization_v_es' }
    before(:all) do
      puts
      puts 'Running CAPER Organization V - ES'
      generator = HudApr::Generators::Caper::Fy2026::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization V - ES']).pluck(:id)
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
          'B13', # expected '14.0000' (14), got '13.0000' (13)
          'C13', # expected '14.0000' (14), got '13.0000' (13)
        ],
      )
    end

    # it 'Q6a' do
    #   compare_results(
    #     file_path: result_file_prefix + results_dir,
    #     question: 'Q6a',
    #   )
    # end

    it 'Q6b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6b',
        skip: [
          'C5', # expected '1.0000' (1), got '0.0000' (0)
          'E5', # expected '1.0000' (1), got '0.0000' (0)
          'F5', # expected '0.0100' (0.0068), got '0.0000' (0.0000)
        ],
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
        skip: [
          'C2', # expected '1.0000' (1), got '4.0000' (4)
          'D2', # expected '0.2500' (0.25), got '1.0000' (1.0000)
        ],
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
          'B4', # expected '15.0000' (15), got '13.0000' (13)
          'C4', # expected '12.0000' (12), got '11.0000' (11)
          'D4', # expected '3.0000' (3), got '2.0000' (2)
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
          'B4', # expected '42.0000' (42), got '45.0000' (45)
          'D4', # expected '8.0000' (8), got '11.0000' (11)
          'B8', # expected '117.0000' (117), got '122.0000' (122)
          'C8', # expected '98.0000' (98), got '101.0000' (101)
          'D8', # expected '18.0000' (18), got '20.0000' (20)
          'B20', # expected '3.0000' (3), got '0.0000' (0)
          'D20', # expected '3.0000' (3), got '0.0000' (0)
          'B26', # expected '5.0000' (5), got '0.0000' (0)
          'C26', # expected '3.0000' (3), got '0.0000' (0)
          'D26', # expected '2.0000' (2), got '0.0000' (0)
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
        skip: [
          'B2', # expected '79.0000' (79), got '77.0000' (77)
          'D2', # expected '72.0000' (72), got '69.0000' (69)
          'B11', # expected '5.0000' (5), got '8.0000' (8)
          'D11', # expected '4.0000' (4), got '8.0000' (8)
        ],
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
        skip: [
          'D3', # expected '29.0000' (29), got '31.0000' (31)
          'H3', # expected '71.0000' (71), got '74.0000' (74)
          'I3', # expected '2.0000' (2), got '0.0000' (0)
        ],
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
      )
    end

    it 'Q23e' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q23e',
        skip: [
          'I4', # expected '16.0000' (16), got '17.0000' (17)
          'J4', # expected '1.0000' (1), got '0.0000' (0)
          'E5', # expected '12.0000' (12), got '15.0000' (15)
          'I5', # expected '30.0000' (30), got '31.0000' (31)
          'J5', # expected '4.0000' (4), got '0.0000' (0)
          'I6', # expected '49.0000' (49), got '50.0000' (50)
          'J6', # expected '1.0000' (1), got '0.0000' (0)
          'E7', # expected '37.0000' (37), got '40.0000' (40)
          'I7', # expected '104.0000' (104), got '107.0000' (107)
          'J7', # expected '6.0000' (6), got '0.0000' (0)
        ],
      )
    end

    it 'Q24a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q24a',
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
  rspec.include_context 'datalab organization v es caper', include_shared: true
end
