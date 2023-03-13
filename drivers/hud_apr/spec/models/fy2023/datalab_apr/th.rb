###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab th coc apr', shared_context: :metadata do
  describe 'Datalab 2021 APR - TH' do
    before(:all) do
      generator = HudApr::Generators::Apr::Fy2023::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: 'DataLab - TH CoC').pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q4a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q4a',
        skip: [
          'L2', # Is the generator name, so not expected to match
          'P2', # Pending AirTable regarding children of CH HoH submitted 1/14/2023 https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec3mJbXygkAoje1t (30)
        ],
      )
    end

    it 'Q5a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q5a',
      )
    end

    it 'Q6a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q6a',
      )
    end

    it 'Q6b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q6b',
      )
    end

    it 'Q6c' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q6c',
      )
    end

    it 'Q6d' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q6d',
      )
    end

    it 'Q6e' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q6e',
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
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q6f',
      )
    end

    it 'Q7a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q7a',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'D3',
          'E3',
          'D6',
          'E6',
        ],
      )
    end

    it 'Q7b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q7b',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'D5',
          'E5',
        ],
      )
    end

    it 'Q8a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q8a',
      )
    end

    it 'Q8b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q8b',
      )
    end

    it 'Q9a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q9a',
      )
    end

    it 'Q9b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q9b',
      )
    end

    it 'Q10a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q10a',
      )
    end

    it 'Q10b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q10b',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'C2',
          'D2',
          'C9',
          'D9',
        ],
      )
    end

    it 'Q10c' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q10c',
      )
    end

    it 'Q11' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q11',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'D3',
          'E3',
          'D13',
          'E13',
        ],
      )
    end

    it 'Q12a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q12a',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'D2',
          'E2',
          'D10',
          'E10',
        ],
      )
    end

    it 'Q12b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q12b',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'D3',
          'E3',
          'D6',
          'E6',
        ],
      )
    end

    it 'Q13a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q13a1',
      )
    end

    it 'Q13a2' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q13a2',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'E2',
          'F2',
          'E9',
          'F9',
        ],
      )
    end

    it 'Q13b1' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q13b1',
      )
    end

    it 'Q13b2' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q13b2',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'E2',
          'F2',
          'E9',
          'F9',
        ],
      )
    end

    it 'Q13c1' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q13c1',
      )
    end

    it 'Q13c2' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q13c2',
      )
    end

    it 'Q14a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q14a',
      )
    end

    it 'Q14b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q14b',
      )
    end

    it 'Q15' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q15',
      )
    end

    it 'Q16' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q16',
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q17',
      )
    end

    it 'Q18' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q18',
      )
    end

    it 'Q19a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q19a1',
      )
    end

    it 'Q19a2' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q19a2',
      )
    end

    it 'Q19b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q19b',
        # Pending AAQ: https://www.hudexchange.info/program-support/my-question/?askaquestionaction=public%3Amain.answer&key=99B4E7C1-9C9A-4C5C-877330D949FEE8A7
        # also https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recJd87KB7pyODgD1 (48)
        skip: [
          'B13',
          'D13',
        ],
      )
    end

    it 'Q20a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q20a',
      )
    end

    it 'Q20b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q20b',
      )
    end

    it 'Q21' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q21',
      )
    end

    it 'Q22a1' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q22a1',
      )
    end

    it 'Q22b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q22b',
      )
    end

    it 'Q22c' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q22c',
      )
    end

    it 'Q22e' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q22e',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'D13',
          'E13',
          'D14',
          'E14',
        ],
      )
    end

    it 'Q23c' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q23c',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'D25',
          'E25',
          'D27',
          'E27',
          'D43',
          'E43',
          'D46',
        ],
      )
    end

    it 'Q25a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25a',
      )
    end

    it 'Q25b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25b',
      )
    end

    it 'Q25c' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25c',
      )
    end

    it 'Q25d' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25d',
      )
    end

    it 'Q25e' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25e',
      )
    end

    it 'Q25f' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25f',
      )
    end

    it 'Q25g' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25g',
      )
    end

    it 'Q25h' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25h',
      )
    end

    it 'Q25i' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q25i',
      )
    end

    it 'Q26a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q26a',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'B3',
          'C3',
          'D3',
          'B5',
          'C5',
          'D5',
        ],
      )
    end

    it 'Q26b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q26b',
        # Pending https://airtable.com/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recatAtoRG7R0ZWaF (51)
        skip: [
          'B3',
          'C3',
          'D3',
          'E3',
          'B5',
          'C5',
          'D5',
          'D6',
          'E6',
        ],
      )
    end

    it 'Q26c' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q26c',
      )
    end

    it 'Q26d' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q26d',
      )
    end

    it 'Q26e' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q26e',
      )
    end

    it 'Q26f' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q26f',
      )
    end

    it 'Q26g' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q26g',
      )
    end

    it 'Q26h' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q26h',
      )
    end

    it 'Q27a' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27a',
      )
    end

    it 'Q27b' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27b',
      )
    end

    it 'Q27c' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27c',
      )
    end

    it 'Q27d' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27d',
      )
    end

    it 'Q27e' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27e',
      )
    end

    it 'Q27f' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27f',
      )
    end

    it 'Q27g' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27g',
      )
    end

    it 'Q27h' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27h',
      )
    end

    it 'Q27i' do
      compare_results(
        file_path: result_file_prefix + 'apr/th_coc',
        question: 'Q27i',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab th coc apr', include_shared: true
end
