###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'datalab organization t es caper', shared_context: :metadata do
  describe 'Datalab 2026 CAPER - Organization T - ES' do
    let(:results_dir) { 'caper/organization_t_es' }
    before(:all) do
      puts
      puts 'Running CAPER Organization T - ES'
      generator = HudApr::Generators::Caper::Fy2026::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization T - ES']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    describe 'internal integrity checks' do
      # If we need to skip any validations in the future, we can add them in the following format:
      # {
      #   'Q7a' => [
      #     'B2', # expected '27.0000' (27), got '26.0000' (26)
      #   ],
      # }
      let(:validation_skips) do
        {
          'Q5a' => ['C2'],
        }
      end
      let(:caper_validations) { ValidationLoader.load_validations['CAPER FY2026'] }

      it 'runs all validation checks' do
        aggregate_failures do
          caper_validations.each do |question, table_validations|
            table_validations.each do |validation|
              next if validation_skips[question]&.include?(validation[:total])
              next unless validation[:source][:relevant_project_types]&.include?(1)

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
          'D6', # expected '7.0000' (7), got '6.0000' (6)
          'E6', # expected '10.0000' (10), got '9.0000' (9)
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
          'B2', # expected '19.0000' (19), got '0.0000' (0)
          'C2', # expected '19.0000' (19), got '0.0000' (0)
          'D2', # expected '1.0000' (1), got '0.0000' (0.0000)
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
        skip: [
          'B2', # expected '39.0000' (39), got '67.0000' (67)
          'C2', # expected '27.0000' (27), got '46.0000' (46)
          'D2', # expected '12.0000' (12), got '21.0000' (21)
          'B3', # expected '35.0000' (35), got '68.0000' (68)
          'C3', # expected '22.0000' (22), got '49.0000' (49)
          'D3', # expected '13.0000' (13), got '19.0000' (19)
          'B4', # expected '35.0000' (35), got '57.0000' (57)
          'C4', # expected '22.0000' (22), got '34.0000' (34)
          'D4', # expected '13.0000' (13), got '23.0000' (23)
          'B5', # expected '27.0000' (27), got '62.0000' (62)
          'C5', # expected '21.0000' (21), got '42.0000' (42)
          'D5', # expected '6.0000' (6), got '20.0000' (20)
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
          'B2', # expected '33.0000' (33), got '52.0000' (52)
          'C2', # expected '26.0000' (26), got '45.0000' (45)
          'B3', # expected '26.0000' (26), got '52.0000' (52)
          'C3', # expected '23.0000' (23), got '48.0000' (48)
          'D3', # expected '3.0000' (3), got '4.0000' (4)
          'B4', # expected '27.0000' (27), got '38.0000' (38)
          'C4', # expected '22.0000' (22), got '33.0000' (33)
          'B5', # expected '25.0000' (25), got '47.0000' (47)
          'C5', # expected '21.0000' (21), got '42.0000' (42)
          'D5', # expected '4.0000' (4), got '5.0000' (5)
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
        skip: [
          'B2', # expected '211.0000' (211), got '216.0000' (216)
          'C2', # expected '198.0000' (198), got '203.0000' (203)
          'B4', # expected '35.0000' (35), got '33.0000' (33)
          'C4', # expected '33.0000' (33), got '31.0000' (31)
          'B5', # expected '38.0000' (38), got '36.0000' (36)
          'C5', # expected '35.0000' (35), got '33.0000' (33)
          'B6', # expected '52.0000' (52), got '53.0000' (53)
          'C6', # expected '45.0000' (45), got '46.0000' (46)
          'B7', # expected '35.0000' (35), got '33.0000' (33)
          'C7', # expected '28.0000' (28), got '26.0000' (26)
        ],
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
        skip: [
          'B2', # expected '211.0000' (211), got '216.0000' (216)
          'C2', # expected '165.0000' (165), got '168.0000' (168)
          'D2', # expected '42.0000' (42), got '44.0000' (44)
          'B4', # expected '35.0000' (35), got '33.0000' (33)
          'C4', # expected '23.0000' (23), got '22.0000' (22)
          'D4', # expected '12.0000' (12), got '11.0000' (11)
          'B5', # expected '38.0000' (38), got '36.0000' (36)
          'C5', # expected '21.0000' (21), got '20.0000' (20)
          'D5', # expected '17.0000' (17), got '16.0000' (16)
          'B6', # expected '52.0000' (52), got '53.0000' (53)
          'C6', # expected '34.0000' (34), got '33.0000' (33)
          'D6', # expected '18.0000' (18), got '20.0000' (20)
          'B7', # expected '35.0000' (35), got '33.0000' (33)
          'D7', # expected '12.0000' (12), got '10.0000' (10)
        ],
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
  rspec.include_context 'datalab organization t es caper', include_shared: true
end
