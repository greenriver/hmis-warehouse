###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'datalab organization j es caper', shared_context: :metadata do
  describe 'Datalab 2026 CAPER - Organization J ES' do
    let(:results_dir) { 'caper/organization_j_es' }
    before(:all) do
      puts
      puts 'Running CAPER Organization J ES'
      generator = HudApr::Generators::Caper::Fy2026::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization J - ES']).pluck(:id)
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
              next unless validation[:source][:relevant_project_types]&.include?(4)

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

    ## Add internal integrity checks for Q16 from TUP observations
    # Sum of B2-B15 should equal B16, etc.
    it 'Q24a internal integrity checks' do
      ['B', 'C', 'D', 'E', 'F'].each do |letter|
        check_sum(
          question: 'Q24a',
          source: (2..15).to_a.map { |i| "#{letter}#{i}" },
          total: "#{letter}16",
        )
      end
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
  rspec.include_context 'datalab organization j es caper', include_shared: true
end
