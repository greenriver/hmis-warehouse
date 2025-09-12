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

    describe 'internal integrity checks' do
      # If we need to skip any validations in the future, we can add them in the following format:
      # {
      #   'Q7a' => [
      #     'B2', # expected '27.0000' (27), got '26.0000' (26)
      #   ],
      # }
      let(:validation_skips) { {} }
      let(:caper_validations) { ValidationLoader.load_validations['CAPER FY2026'] }

      it 'runs all validation checks' do
        caper_validations.each do |question, table_validations|
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
          'B13', # expected '14.0000' (14), got '13.0000' (13)
          'C13', # expected '14.0000' (14), got '13.0000' (13)
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
          'B11', # expected '5.0000' (5), got '7.0000' (7)
          'D11', # expected '4.0000' (4), got '7.0000' (7)
        ],
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q17',
        skip: [
          'D17', # expected '132.0000' (132), got '130.0000' (130)
        ],
      )
    end

    it 'Q19b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19b',
        skip: [
          'B5', # expected '16.0000' (16), got '17.0000' (17)
          'D5', # expected '19.0000' (19), got '20.0000' (20)
          'E5', # expected '0.8400' (0.8421), got '0.8500' (0.8500)
          'B17', # expected '29.0000' (29), got '28.0000' (28)
          'C17', # expected '38.0000' (38), got '36.0000' (36)
          'D17', # expected '67.0000' (67), got '64.0000' (64)
          'E17', # expected '0.4300' (0.4328), got '0.4400' (0.4375)
          'F17', # expected '3.0000' (3), got '1.0000' (1)
          'H17', # expected '5.0000' (5), got '3.0000' (3)
          'I17', # expected '0.6000' (0.6000), got '0.3300' (0.3333)
          'C18', # expected '56.0000' (56), got '54.0000' (54)
          'D18', # expected '121.0000' (121), got '119.0000' (119)
        ],
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
          'H3', # expected '71.0000' (71), got '72.0000' (72)
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
