###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab rrh esg caper', shared_context: :metadata do
  describe 'Datalab 2023 CAPER - RRH ESG' do
    before(:all) do
      generator = HudApr::Generators::Caper::Fy2023::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: 'DataLab - RRH ESG I').pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q4a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q4a',
        skip: [
          'L2', # Is the generator name, so not expected to match
        ],
      )
    end

    it 'Q5a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q5a',
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q6a',
      )
    end

    it 'Q6b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q6b',
      )
    end

    it 'Q6c' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q6c',
      )
    end

    it 'Q6d' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q6d',
      )
    end

    it 'Q6e' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q6e',
        # pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recWCP4jftXR51nYq (47)
        skip: [
          'C4',
          'C6',
        ],
      )
    end

    it 'Q6f' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q6f',
      )
    end

    it 'Q7a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q7a',
      )
    end

    it 'Q7b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q7b',
      )
    end

    it 'Q8a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q8a',
      )
    end

    it 'Q8b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q8b',
      )
    end

    it 'Q9a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q9a',
      )
    end

    it 'Q9b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q9b',
      )
    end

    it 'Q10a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q10a',
      )
    end

    it 'Q10b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q10b',
      )
    end

    it 'Q10c' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q10c',
      )
    end

    it 'Q10d' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q10d',
      )
    end

    it 'Q11' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q11',
      )
    end

    it 'Q12a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q12a',
      )
    end

    it 'Q12b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q12b',
      )
    end

    it 'Q13a1' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q13a1',
      )
    end

    it 'Q13b1' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q13b1',
      )
    end

    it 'Q13c1' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q13c1',
      )
    end

    it 'Q14a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q14a',
      )
    end

    it 'Q14b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q14b',
      )
    end

    it 'Q15' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q15',
      )
    end

    it 'Q16' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q16',
        # Pending AirTable submitted 1/16/2023 Issue ID 37
        skip: [
          'B2',
          'D2',
          'B11',
          'D11',
        ],
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q17',
      )
    end

    it 'Q19b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q19b',
        # Pending AAQ: https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=99B4E7C1-9C9A-4C5C-877330D949FEE8A7
        skip: [
          'B13',
          'D13',
          'E13',
        ],
      )
    end

    it 'Q20a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q20a',
      )
    end

    it 'Q21' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q21',
      )
    end

    it 'Q22a2' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q22a2',
      )
    end

    it 'Q22c' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q22c',
        # Pending AirTable submitted 1/16/2023 Issue ID 38
        skip: [
          'B11',
          'C11',
        ],
      )
    end

    it 'Q22d' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q22d',
      )
    end

    it 'Q22e' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q22e',
      )
    end

    it 'Q23c' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q23c',
      )
    end

    it 'Q24' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q24',
      )
    end

    it 'Q25a' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q25a',
      )
    end

    it 'Q26b' do
      compare_results(
        file_path: result_file_prefix + 'caper/rrh_esg',
        question: 'Q26b',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab rrh esg caper', include_shared: true
end
