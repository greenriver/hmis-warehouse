###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab sso coc apr', shared_context: :metadata do
  describe 'Datalab 2023 APR - Services Only' do
    before(:all) do
      generator = HudApr::Generators::Apr::Fy2023::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: 'DataLab - SSO CoC').pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q4a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q4a',
        skip: [
          'B2', # expected is a name not and ID?
          'L2', # Is the generator name, so not expected to match
        ],
      )
    end

    it 'Q5a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q5a',
        # Pending AirTable from 1/13/2023 LOT Method 1 – Using Start/Exit Dates Issue ID 25
        skip: [
          'B17',
          'C17',
        ],
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q6a',
      )
    end

    it 'Q6b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q6b',
      )
    end

    it 'Q6c' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q6c',
        # Pending AirTable submitted 1/13/2023 Issue ID 26
        skip: [
          'B5',
          'C5',
        ],
      )
    end

    it 'Q6d' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q6d',
      )
    end

    it 'Q6e' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q6e',
      )
    end

    it 'Q6f' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q6f',
      )
    end

    it 'Q7a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q7a',
      )
    end

    it 'Q7b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q7b',
        # Pending AAQ: Datalab Test Kit 2.0 APR Q7 - submitted 9/29/2022
        # skip: [
        #   'B2',
        #   'C2',
        # ],
      )
    end

    it 'Q8a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q8a',
      )
    end

    it 'Q8b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q8b',
        # Pending AAQ: Datalab Test Kit 2.0 APR Q7 - submitted 9/29/2022
        # skip: [
        #   'B2',
        #   'C2',
        # ],
      )
    end

    it 'Q9a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q9a',
      )
    end

    it 'Q9b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q9b',
      )
    end

    it 'Q10a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q10a',
      )
    end

    it 'Q10b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q10b',
      )
    end

    it 'Q10c' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q10c',
      )
    end

    it 'Q11' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q11',
      )
    end

    it 'Q12a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q12a',
      )
    end

    it 'Q12b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q12b',
      )
    end

    it 'Q13a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q13a1',
      )
    end

    it 'Q13a2' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q13a2',
      )
    end

    it 'Q1ba1' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q13b1',
      )
    end

    it 'Q13b2' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q13b2',
      )
    end

    it 'Q13c1' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q13c1',
      )
    end

    it 'Q13c2' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q13c2',
      )
    end

    it 'Q14a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q14a',
      )
    end

    it 'Q14b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q14b',
      )
    end

    it 'Q15' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q15',
      )
    end

    it 'Q16' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q16',
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q17',
      )
    end

    it 'Q18' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q18',
      )
    end

    it 'Q19a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q19a1',
      )
    end

    it 'Q19a2' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q19a2',
        # Pending AirTable submitted 1/13/2023 Issue ID 27 and 36
        skip: [
          'B4',
          'G4',
          'B5',
        ],
      )
    end

    it 'Q19b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q19b',
        # Pending AAQ: https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=99B4E7C1-9C9A-4C5C-877330D949FEE8A7
        # IncomeFromAnySource = 0, but do have earned income
        skip: [
          'C13',
          'D13',
        ],
      )
    end

    it 'Q20a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q20a',
      )
    end

    it 'Q20b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q20b',
      )
    end

    it 'Q21' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q21',
      )
    end

    it 'Q22a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q22a1',
      )
    end

    it 'Q22b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q22b',
      )
    end

    it 'Q22c' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q22c',
      )
    end

    it 'Q22e' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q22e',
      )
    end

    it 'Q23c' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q23c',
      )
    end

    it 'Q25a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25a',
      )
    end

    it 'Q25b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25b',
        # pending AirTable from 1/13/2023 regarding ChildrenOnly household
        skip: [
          'B6',
          'B7',
        ],
      )
    end

    it 'Q25c' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25c',
      )
    end

    it 'Q25d' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25d',
      )
    end

    it 'Q25e' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25e',
      )
    end

    it 'Q25f' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25f',
      )
    end

    it 'Q25g' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25g',
      )
    end

    it 'Q25h' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25h',
      )
    end

    it 'Q25i' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q25i',
      )
    end

    it 'Q26a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q26a',
        # pending AirTable 1/13/2023 related to https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=6B4F6314-CD74-429E-9DF7E4E93C938AD4
        skip: [
          'B3',
          'E3',
          'B5',
          'E5',
        ],
      )
    end

    it 'Q26b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q26b',
        # pending AirTable 1/13/2023 related to https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=6B4F6314-CD74-429E-9DF7E4E93C938AD4
        skip: [
          'B3',
          'E3',
          'B5',
          'E5',
        ],
      )
    end

    it 'Q26c' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q26c',
      )
    end

    it 'Q26d' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q26d',
      )
    end

    it 'Q26e' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q26e',
      )
    end

    it 'Q26f' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q26f',
      )
    end

    it 'Q26g' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q26g',
      )
    end

    it 'Q26h' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q26h',
      )
    end

    it 'Q27a' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27a',
      )
    end

    it 'Q27b' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27b',
      )
    end

    it 'Q27c' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27c',
      )
    end

    it 'Q27d' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27d',
      )
    end

    it 'Q27e' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27e',
      )
    end

    it 'Q27f' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27f',
      )
    end

    it 'Q27g' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27g',
      )
    end

    it 'Q27h' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27h',
      )
    end

    it 'Q27i' do
      compare_results(
        file_path: result_file_prefix + 'apr/sso_coc',
        question: 'Q27i',
        # Pending AAQ: https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=99B4E7C1-9C9A-4C5C-877330D949FEE8A7
        # IncomeFromAnySource = 0, but do have earned income
        skip: [
          'C13',
          'D13',
          'J13',
          'L13',
          'M13',
          'M14',
        ],
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab sso coc apr', include_shared: true
end
