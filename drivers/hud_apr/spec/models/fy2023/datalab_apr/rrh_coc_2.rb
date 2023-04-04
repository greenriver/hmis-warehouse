###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab rrh coc 2 apr', shared_context: :metadata do
  describe 'Datalab 2023 APR - RRH CoC II and DataLab - RRH CoC I projects' do
    before(:all) do
      generator = HudApr::Generators::Apr::Fy2023::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['DataLab - RRH CoC II', 'DataLab - RRH CoC I']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q4a' do
      question = 'Q4a'
      goals = goals(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: question,
      )
      compare_columns(goal: goals, question: question, column_names: ['C', 'D'])
    end

    it 'Q5a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q5a',
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q6a',
      )
    end

    it 'Q6b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q6b',
      )
    end

    it 'Q6c' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q6c',
      )
    end

    it 'Q6d' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q6d',
      )
    end

    it 'Q6e' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q6e',
        # Pending https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=CAA8AE17-22C4-447B-AA191B21C984CBA7
        # pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recWCP4jftXR51nYq (47)
        skip: [
          'C2',
          'C3',
          'C4',
          'C5',
          'C6',
        ],
      )
    end

    it 'Q6f' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q6f',
      )
    end

    it 'Q7a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q7a',
      )
    end

    it 'Q7b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q7b',
        detail_columns: [
          :last_name,
          :first_name,
        ],
      )
    end

    it 'Q8a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q8a',
      )
    end

    it 'Q8b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q8b',
      )
    end

    it 'Q9a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q9a',
      )
    end

    it 'Q9b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q9b',
      )
    end

    it 'Q10a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q10a',
      )
    end

    it 'Q10b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q10b',
      )
    end

    it 'Q10c' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q10c',
      )
    end

    it 'Q11' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q11',
      )
    end

    it 'Q12a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q12a',
      )
    end

    it 'Q12b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q12b',
      )
    end

    it 'Q13a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q13a1',
      )
    end

    it 'Q13a2' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q13a2',
      )
    end

    it 'Q1ba1' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q13b1',
      )
    end

    it 'Q13b2' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q13b2',
      )
    end

    it 'Q13c1' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q13c1',
      )
    end

    it 'Q13c2' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q13c2',
      )
    end

    it 'Q14a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q14a',
      )
    end

    it 'Q14b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q14b',
      )
    end

    it 'Q15' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q15',
      )
    end

    it 'Q16' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q16',
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q17',
      )
    end

    it 'Q18' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q18',
      )
    end

    it 'Q19a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q19a1',
      )
    end

    it 'Q19a2' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q19a2',
      )
    end

    it 'Q19b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q19b',
        # Pending AAQ: https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=99B4E7C1-9C9A-4C5C-877330D949FEE8A7
        # and https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recJd87KB7pyODgD1 (48)
        skip: [
          'B13',
          'C13',
          'D13',
          'E13',
        ],
      )
    end

    it 'Q20a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q20a',
      )
    end

    it 'Q20b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q20b',
      )
    end

    it 'Q21' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q21',
      )
    end

    it 'Q22a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q22a1',
      )
    end

    it 'Q22b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q22b',
      )
    end

    it 'Q22c' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q22c',
      )
    end

    it 'Q22e' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q22e',
      )
    end

    it 'Q23c' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q23c',
      )
    end

    it 'Q25a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25a',
      )
    end

    it 'Q25b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25b',
      )
    end

    it 'Q25c' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25c',
      )
    end

    it 'Q25d' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25d',
      )
    end

    it 'Q25e' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25e',
      )
    end

    it 'Q25f' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25f',
      )
    end

    it 'Q25g' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25g',
      )
    end

    it 'Q25h' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25h',
      )
    end

    it 'Q25i' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q25i',
      )
    end

    it 'Q26a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q26a',
      )
    end

    it 'Q26b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q26b',
      )
    end

    it 'Q26c' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q26c',
      )
    end

    it 'Q26d' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q26d',
      )
    end

    it 'Q26e' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q26e',
      )
    end

    it 'Q26f' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q26f',
      )
    end

    it 'Q26g' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q26g',
      )
    end

    it 'Q26h' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q26h',
      )
    end

    it 'Q27a' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27a',
      )
    end

    it 'Q27b' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27b',
      )
    end

    it 'Q27c' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27c',
      )
    end

    it 'Q27d' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27d',
      )
    end

    it 'Q27e' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27e',
      )
    end

    it 'Q27f' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27f',
      )
    end

    it 'Q27g' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27g',
      )
    end

    it 'Q27h' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27h',
      )
    end

    it 'Q27i' do
      compare_results(
        file_path: result_file_prefix + 'apr/rrh_coc_2',
        question: 'Q27i',
        # Pending AAQ: https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=99B4E7C1-9C9A-4C5C-877330D949FEE8A7
        skip: [
          'B13',
          'D13',
          'E13',
          'M14',
        ],
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab rrh coc 2 apr', include_shared: true
end
