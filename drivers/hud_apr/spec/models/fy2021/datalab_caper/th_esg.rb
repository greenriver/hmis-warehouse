###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab th esg caper', shared_context: :metadata do
  describe 'Datalab 2021 CAPER - TH ESG' do
    before(:all) do
      generator = HudApr::Generators::Caper::Fy2021::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: 'DataLab - TH ESG').pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q4a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q4a',
        skip: [
          'B2', # expected is a name not and ID?
          'L2', # Is the generator name, so not expected to match
        ],
      )
    end

    it 'Q5a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q5a',
        # Q5 B11 - needs to look at disabilities to determine if the client has a disabling condition
        # save as a calculated field any disabilities at entry
        # Pending AAQ: [CAPER] DataLab - ES-NbN ESG (D) Q5a Number of chronically homeless persons - submitted 10/4/2022
        skip: [
          'B11',
        ],
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q6a',
      )
    end

    it 'Q6b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q6b',
      )
    end

    it 'Q6c' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q6c',
      )
    end

    it 'Q6d' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q6d',
      )
    end

    it 'Q6e' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q6e',
      )
    end

    it 'Q6f' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q6f',
      )
    end

    it 'Q7a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q7a',
      )
    end

    it 'Q7b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q7b',
      )
    end

    it 'Q8a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q8a',
      )
    end

    it 'Q8b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q8b',
      )
    end

    it 'Q9a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q9a',
      )
    end

    it 'Q9b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q9b',
      )
    end

    it 'Q10a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q10a',
      )
    end

    it 'Q10b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q10b',
      )
    end

    it 'Q10c' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q10c',
      )
    end

    it 'Q10d' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q10d',
      )
    end

    it 'Q11' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q11',
      )
    end

    it 'Q12a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q12a',
      )
    end

    it 'Q12b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q12b',
      )
    end

    it 'Q13a1' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q13a1',
      )
    end

    it 'Q13b1' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q13b1',
      )
    end

    it 'Q13c1' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q13c1',
      )
    end

    it 'Q14a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q14a',
      )
    end

    it 'Q14b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q14b',
      )
    end

    it 'Q15' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q15',
      )
    end

    it 'Q16' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q16',
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q17',
      )
    end

    it 'Q19b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q19b',
      )
    end

    it 'Q20a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q20a',
      )
    end

    it 'Q21' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q21',
      )
    end

    it 'Q22a2' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q22a2',
      )
    end

    it 'Q22c' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q22c',
      )
    end

    it 'Q22d' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q22d',
      )
    end

    it 'Q22e' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q22e',
        # Pending AAQ: [APR] DataLab - RRH CoC I & DataLab - RRH CoC II (D) Q22e - submitted 10/2/2022
        skip: [
          'B7', # children Rhododendron Phosphorescent and Avocada Pugnacious should inherit from HoH
          'D7',
          'B8', # Cashew Patriarch and Prosper Dainty should inherit from HoH
          'D8',
          'B9',
          'D9',
          'B11',
          'D11',
          'B13',
          'D13',
        ],
      )
    end

    it 'Q23c' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q23c',
      )
    end

    it 'Q24' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q24',
      )
    end

    it 'Q25a' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q25a',
      )
    end

    it 'Q26b' do
      compare_results(
        file_path: result_file_prefix + 'caper/th_esg',
        question: 'Q26b',
        # Q5 B11 - needs to look at disabilities to determine if the client has a disabling condition
        # save as a calculated field any disabilities at entry
        # Pending AAQ: [CAPER] DataLab - ES-NbN ESG (D) Q5a Number of chronically homeless persons - submitted 10/4/2022
        skip: [
          'B2',
          'D2',
          'B3',
          'D3',
        ],
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab so esg caper', include_shared: true
end
