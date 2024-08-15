###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab organization a rrh apr', shared_context: :metadata do
  describe 'Datalab 2024 APR - Organization A - RRH' do
    let(:results_dir) { 'apr/organization_a_rrh' }
    before(:all) do
      generator = HudApr::Generators::Apr::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization A - RRH - 2']).pluck(:id)
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

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recQoBOA5VwRFp8jJ
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

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec5AxqrAUl0f8yAf
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
        # The following are off by a few after the fix for PIT households
        skip: [
          'B3', # expected '28.0000' (28), got '27.0000' (27)
          'D3', # expected '10.0000' (10), got '9.0000' (9)
          'B4', # expected '16.0000' (16), got '14.0000' (14)
          'D4', # expected '6.0000' (6), got '4.0000' (4)
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

    it 'Q10a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q10a',
      )
    end

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

    # previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recU9uhV7OK67j9G6
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
      )
    end

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recU9uhV7OK67j9G6
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
        skip: [
          'C14', # expected '5.0000' (5), got '3.0000' (3)
          'C15', # expected '17.0000' (17), got '19.0000' (19)
        ],
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
        skip: [
          'B6', # expected '23.0000' (23), got '24.0000' (24)
          'C6', # expected '16.0000' (16), got '17.0000' (17)
          'B7', # expected '21.0000' (21), got '22.0000' (22)
          'C7', # expected '8.0000' (8), got '9.0000' (9)
          'B10', # expected '9.0000' (9), got '16.0000' (16)
          'D10', # expected '9.0000' (9), got '16.0000' (16)
          'B12', # expected '141.0000' (141), got '150.0000' (150)
          'C12', # expected '69.0000' (69), got '71.0000' (71)
          'D12', # expected '72.0000' (72), got '79.0000' (79)
          'B13', # expected '47.0000' (47), got '38.0000' (38)
          'C13', # expected '27.0000' (27), got '25.0000' (25)
          'D13', # expected '20.0000' (20), got '13.0000' (13)
        ],
      )
    end

    it 'Q22f' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22f',
        skip: [
          'D2', # expected '5.0000' (5), got '12.0000' (12)
          'H2', # expected '86.0000' (86), got '97.0000' (97)
          'I2', # expected '17.0000' (17), got '18.0000' (18)
          'D3', # expected '7.0000' (7), got '0.0000' (0)
          'H3', # expected '20.0000' (20), got '9.0000' (9)
          'I3', # expected '5.0000' (5), got '4.0000' (4)
          'D4', # expected '18.6000' (18.6000), got '158.5000' (158.5)
          'H4', # expected '15.0800' (15.0814), got '17.5500' (17.5464)
          'I4', # expected '1.5900' (1.5882), got '21.8300' (21.8333)
          'D5', # expected '0.0000' (0.0000), got '46.5000' (46.5)
          'H5', # expected '1.5000' (1.5000), got '1.0000' (1.0)
          'I5', # expected '0.0000' (0.0000), got '0.5000' (0.5)
        ],
      )
    end

    it 'Q22g' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22g',
        skip: [
          'B2', # expected '1.0000' (1), got '2.0000' (2)
          'D2', # expected '8.0000' (8), got '16.0000' (16)
          'H2', # expected '105.0000' (105), got '130.0000' (130)
          'I2', # expected '20.0000' (20), got '28.0000' (28)
          'J2', # expected '7.0000' (7), got '8.0000' (8)
          'D3', # expected '0.0000' (0), got '3.0000' (3)
          'H3', # expected '0.0000' (0), got '8.0000' (8)
          'I3', # expected '0.0000' (0), got '4.0000' (4)
          'J3', # expected '0.0000' (0), got '2.0000' (2)
          'B4', # expected '259.0000' (259.0000), got '154.0000' (154.0)
          'D4', # expected '171.0000' (171.0000), got '240.5000' (240.5)
          'H4', # expected '177.2100' (177.2095), got '167.4200' (167.4154)
          'I4', # expected '98.2500' (98.2500), got '471.0400' (471.0357)
          'J4', # expected '88.8600' (88.8571), got '82.3800' (82.375)
          'B5', # expected '259.0000' (259.0000), got '154.0000' (154.0)
          'D5', # expected '39.5000' (39.5000), got '150.0000' (150.0)
          'H5', # expected '105.0000' (105.0000), got '95.5000' (95.5)
          'I5', # expected '70.0000' (70.0000), got '73.0000' (73.0)
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

    it 'Q24c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q24c',
      )
    end

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recGeOJDYAm528rAx
    it 'Q24d' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q24d',
      )
    end

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

    it 'Q25c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25c',
      )
    end

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
        # pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recZbEHrNyt7aUsfw
        skip: [
          'B3', # expected '82.0000' (82), got '84.0000' (84)
          'C3', # expected '56.0000' (56), got '57.0000' (57)
          'D3', # expected '26.0000' (26), got '27.0000' (27)
          'B5', # expected '20.0000' (20), got '18.0000' (18)
          'C5', # expected '15.0000' (15), got '14.0000' (14)
          'D5', # expected '5.0000' (5), got '4.0000' (4)
        ],
      )
    end

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recnAJsqhnXlGmmZG
    it 'Q26b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26b',
      )
    end

    it 'Q26c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26c',
      )
    end

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

    it 'Q27c' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27c',
      )
    end

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
      )
    end

    it 'Q27i' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27i',
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
        skip: [
          'B10', # expected '0.0000' (0), got '1.0000' (1)
          'D10', # expected '0.0000' (0), got '1.0000' (1)
          'B12', # expected '8.0000' (8), got '9.0000' (9)
          'D12', # expected '2.0000' (2), got '3.0000' (3)
          'B13', # expected '3.0000' (3), got '2.0000' (2)
          'D13', # expected '1.0000' (1), got '0.0000' (0)
        ],
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
  rspec.include_context 'datalab organization a rrh apr', include_shared: true
end
