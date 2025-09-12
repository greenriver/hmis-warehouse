###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../../../datalab_testkit/spec/models/validation_loader'

RSpec.shared_context 'datalab multiple projects apr', shared_context: :metadata do
  describe 'Datalab 2026 APR - Multiple Projects' do
    let(:results_dir) { 'apr/multiple_projects' }
    before(:all) do
      puts
      puts 'Running APR Multiple Projects'
      generator = HudApr::Generators::Apr::Fy2026::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization X - RRH', 'Organization M - RRH - 2']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    describe 'internal integrity checks' do
      # If we need to skip any validations in the future, we can add them in the following format:
      # {
      #   'Q7a' => [
      #     'B2', # expected '27.0000' (27), got '26.0000' (26)
      #   ],
      # }
      let(:validation_skips) { {} }
      let(:apr_validations) { ValidationLoader.load_validations['APR FY2026'] }

      it 'runs all validation checks' do
        apr_validations.each do |question, table_validations|
          table_validations.each do |validation|
            next if validation_skips[question]&.include?(validation[:total])

            aggregate_failures do
              check_sum(validation: validation, question: question)
            end
          end
        end
      end
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
          'B17', # expected '5.0000' (5), got '4.0000' (4)
          'C17', # expected '5.0000' (5), got '4.0000' (4)
        ],
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6a',
      )
    end

    it 'Q6b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q6b',
        skip: [
          'D3', # expected '0.0000' (0), got '3.0000' (3)
          'E3', # expected '0.0000' (0), got '3.0000' (3)
          'F3', # expected '0.0000' (0.0000), got '0.0100' (0.0062)
          'D6', # expected '9.0000' (9), got '7.0000' (7)
          'E6', # expected '9.0000' (9), got '7.0000' (7)
          'F6', # expected '0.0200' (0.0186), got '0.0100' (0.0144)
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
          'B2', # expected '27.0000' (27), got '26.0000' (26)
          'C2', # expected '21.0000' (21), got '20.0000' (20)
          'B3', # expected '36.0000' (36), got '35.0000' (35)
          'C3', # expected '23.0000' (23), got '22.0000' (22)
          'B4', # expected '71.0000' (71), got '70.0000' (70)
          'C4', # expected '48.0000' (48), got '47.0000' (47)
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

    it 'Q13a2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q13a2',
      )
    end

    it 'Q13b2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q13b2',
      )
    end

    it 'Q13c2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q13c2',
        skip: [
          'B3', # expected '64.0000' (64), got '65.0000' (65)
          'C3', # expected '40.0000' (40), got '41.0000' (41)
          'B4', # expected '30.0000' (30), got '29.0000' (29)
          'C4', # expected '22.0000' (22), got '21.0000' (21)
        ],
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

    it 'Q18' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q18',
      )
    end

    it 'Q19a1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19a1',
        skip: [
          'G2', # expected '2.0000' (2), got '1.0000' (1)
          'H2', # expected '5.0000' (5), got '4.0000' (4)
          'J2', # expected '0.2000' (0.2000), got '0.2500' (0.2500)
          'G4', # expected '4.0000' (4), got '3.0000' (3)
          'H4', # expected '5.0000' (5), got '4.0000' (4)
          'G6', # expected '1.0000' (1), got '0.0000' (0)
          'H6', # expected '5.0000' (5), got '4.0000' (4)
          'J6', # expected '0.2000' (0.2000), got '0.2500' (0.2500)
          'H7', # expected '40.0000' (40.00), got '50.0000' (50.00)
        ],
      )
    end

    it 'Q19a2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19a2',
      )
    end

    it 'Q19b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19b',
        skip: [
          'C17', # expected '7.0000' (7), got '6.0000' (6)
          'D17', # expected '25.0000' (25), got '24.0000' (24)
          'E17', # expected '0.7200' (0.7200), got '0.7500' (0.7500)
        ],
      )
    end

    it 'Q20a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q20a',
      )
    end

    it 'Q20b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q20b',
      )
    end

    it 'Q21' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q21',
      )
    end

    it 'Q22a1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22a1',
      )
    end

    it 'Q22b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22b',
      )
    end

    it 'Q22c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22c',
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
          'D3', # expected '0.0000' (0), got '66.0000' (66)
          'E3', # expected '0.0000' (0), got '1.0000' (1)
          'H3', # expected '0.0000' (0), got '33.0000' (33)
          'I3', # expected '0.0000' (0), got '6.0000' (6)
          'J3', # expected '0.0000' (0), got '11.0000' (11)
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
      )
    end

    it 'Q24b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q24b',
      )
    end

    # Removed in 2026
    # it 'Q24c' do
    #   compare_results(
    #     file_path: result_file_prefix + results_dir,
    #     question: 'Q24c',
    #   )
    # end

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

    it 'Q25b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25b',
      )
    end

    # Removed in 2026
    # it 'Q25c' do
    #   compare_results(
    #     file_path: result_file_prefix + results_dir,
    #     question: 'Q25c',
    #   )
    # end

    it 'Q25d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25d',
      )
    end

    it 'Q25i' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25i',
      )
    end

    it 'Q25j' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25j',
      )
    end

    it 'Q26a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26a',
      )
    end

    it 'Q26b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26b',
      )
    end

    # Removed in 2026
    # it 'Q26c' do
    #   compare_results(
    #     file_path: result_file_prefix + results_dir,
    #     question: 'Q26c',
    #   )
    # end

    it 'Q26d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26d',
      )
    end

    it 'Q26e' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26e',
      )
    end

    it 'Q27a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27a',
      )
    end

    it 'Q27b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27b',
      )
    end

    # Removed in 2026
    # it 'Q27c' do
    #   compare_results(
    #     file_path: result_file_prefix + results_dir,
    #     question: 'Q27c',
    #   )
    # end

    it 'Q27d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27d',
      )
    end

    it 'Q27e' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27e',
      )
    end

    it 'Q27f1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27f1',
      )
    end

    it 'Q27f2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27f2',
      )
    end

    it 'Q27g' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27g',
      )
    end

    it 'Q27h' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27h',
        skip: [
          'D12', # expected '17.0000' (17), got '16.0000' (16)
        ],
      )
    end

    it 'Q27i' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27i',
        skip: [
          'G2', # expected '5.0000' (5), got '4.0000' (4)
          'H2', # expected '5.0000' (5), got '4.0000' (4)
          'G18', # expected '5.0000' (5), got '4.0000' (4)
          'H18', # expected '5.0000' (5), got '4.0000' (4)
        ],
      )
    end

    it 'Q27j' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27j',
      )
    end

    it 'Q27k' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27k',
      )
    end

    it 'Q27l' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27l',
      )
    end

    it 'Q27m' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27m',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab multiple projects apr', include_shared: true
end
