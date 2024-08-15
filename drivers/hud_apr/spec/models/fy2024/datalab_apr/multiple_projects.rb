###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab multiple projects apr', shared_context: :metadata do
  describe 'Datalab 2024 APR - Multiple Projects' do
    let(:results_dir) { 'apr/multiple_projects' }
    before(:all) do
      generator = HudApr::Generators::Apr::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization A - RRH - 2', 'Organization S - RRH - 2']).pluck(:id)
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

    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec5AxqrAUl0f8yAf
    it 'Q8b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8b',
        skip: [
          'B3', # expected '68.0000' (68), got '67.0000' (67)
          'D3', # expected '20.0000' (20), got '19.0000' (19)
          'B4', # expected '73.0000' (73), got '70.0000' (70)
          'D4', # expected '18.0000' (18), got '15.0000' (15)
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

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recZpSZRB8G1UWVsp
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

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recZpSZRB8G1UWVsp
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

    # previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recU9uhV7OK67j9G6
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

    # previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recLnlLoLpQ2Dh1SI
    it 'Q20a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q20a',
      )
    end

    # previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recZnCM2MofvBQIo5
    # previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recLuAql3MuuusByb
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
          'C15', # expected '138.0000' (138), got '140.0000' (140)
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
          'B6', # expected '60.0000' (60), got '59.0000' (59)
          'C6', # expected '40.0000' (40), got '41.0000' (41)'
          'D6', # expected '20.0000' (20), got '18.0000' (18)'
          'B7', # expected '62.0000' (62), got '63.0000' (63)'
          'C7', # expected '27.0000' (27), got '28.0000' (28)'
          'B8', # expected '110.0000' (110), got '111.0000' ('111)
          'D8', # expected '61.0000' (61), got '62.0000' (62)'
          'B10', # expected '23.0000' (23), got '30.0000' (30)'
          'D10', # expected '12.0000' (12), got '19.0000' (19)'
          'B12', # expected '382.0000' (382), got '390.0000' ('390)
          'C12', # expected '211.0000' (211), got '213.0000' ('213)
          'D12', # expected '171.0000' (171), got '177.0000' ('177)
          'B13', # expected '110.0000' (110), got '100.0000' ('100)
          'C13', # expected '68.0000' (68), got '66.0000' (66)'
          'D13', # expected '42.0000' (42), got '34.0000' (34)'
          'B14', # expected '17.0000' (17), got '19.0000' (19)'
          'D14', # expected '16.0000' (16), got '18.0000' (18)'
        ],
      )
    end

    it 'Q22f' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22f',
        skip: [
          'D2', # expected '88.0000' (88), got '95.0000' (95)
          'H2', # expected '125.0000' (125), got '137.0000' (137)
          'I2', # expected '23.0000' (23), got '24.0000' (24)
          'J2', # expected '26.0000' (26), got '27.0000' (27)
          'D3', # expected '26.0000' (26), got '19.0000' (19)
          'H3', # expected '25.0000' (25), got '13.0000' (13)
          'I3', # expected '6.0000' (6), got '5.0000' (5)
          'J3', # expected '4.0000' (4), got '3.0000' (3)
          'D4', # expected '38.7200' (38.7159), got '54.9100' (54.9053)
          'H4', # expected '25.0200' (25.0160), got '26.0400' (26.0365)
          'I4', # expected '7.0400' (7.0435), got '22.0000' (22.0)
          'J4', # expected '34.1500' (34.1538), got '32.8900' (32.8889)
          'D5', # expected '13.0000' (13.0000), got '15.0000' (15.0)
          'I5', # expected '1.0000' (1.0000), got '1.5000' (1.5)
          'J5', # expected '4.5000' (4.5000), got '4.0000' (4.0)
        ],
      )
    end

    it 'Q22g' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22g',
        skip: [
          'B2', # expected '3.0000' (3), got '4.0000' (4)
          'C2', # expected '0.0000' (0), got '1.0000' (1)
          'D2', # expected '129.0000' (129), got '170.0000' (170)
          'H2', # expected '182.0000' (182), got '222.0000' (222)
          'I2', # expected '27.0000' (27), got '38.0000' (38)
          'J2', # expected '41.0000' (41), got '48.0000' (48)
          'C3', # expected '0.0000' (0), got '1.0000' (1)
          'D3', # expected '0.0000' (0), got '10.0000' (10)
          'H3', # expected '0.0000' (0), got '8.0000' (8)
          'I3', # expected '0.0000' (0), got '4.0000' (4)
          'J3', # expected '0.0000' (0), got '3.0000' (3)
          'B4', # expected '118.6700' (118.6667), got '101.2500' (101.25)
          'C4', # expected '0.0000' (0.0000), got '88.0000' (88.0)
          'D4', # expected '404.2800' (404.2791), got '354.9300' (354.9294)
          'H4', # expected '253.5700' (253.5659), got '256.4100' (256.4144)
          'I4', # expected '101.4400' (101.4444), got '375.1100' (375.1053)
          'J4', # expected '306.7600' (306.7561), got '280.8100' (280.8125)
          'B5', # expected '67.0000' (67.0000), got '58.0000' (58.0)
          'C5', # expected '0.0000' (0.0000), got '88.0000' (88.0)
          'H5', # expected '116.5000' (116.5000), got '108.0000' (108.0)
          'J5', # expected '96.0000' (96.0000), got '98.5000' (98.5)
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

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recnAJsqhnXlGmmZG
    # Not counting children with HoH or adult in CH calculation
    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recT9z9YkbQtWwAmm
    it 'Q25b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25b',
        skip: [
          'B4', # expected '323.0000' (323), got '322.0000' (322)
          'D4', # expected '70.0000' (70), got '69.0000' (69)
        ],
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
          'B3', # expected '247.0000' (247), got '249.0000' (249)
          'C3', # expected '185.0000' (185), got '186.0000' (186)
          'D3', # expected '62.0000' (62), got '63.0000' (63)
          'B5', # expected '20.0000' (20), got '18.0000' (18)
          'C5', # expected '15.0000' (15), got '14.0000' (14)
          'D5', # expected '5.0000' (5), got '4.0000' (4)
        ],
      )
    end

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recnAJsqhnXlGmmZG
    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recTCOE44QtrUKsfZ
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
        # We round, it's unclear what the expectation is
        skip: [
          'B2', # expected '186.8400' (186.8421), got '187.0000' (187)
          'C2', # expected '165.4200' (165.4167), got '165.0000' (165)
        ],
      )
    end

    # Previous AirTable https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recUA83elKFt0P9r
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
          'B10', # expected '1.0000' (1), got '2.0000' (2)
          'D10', # expected '0.0000' (0), got '1.0000' (1)
          'B12', # expected '26.0000' (26), got '27.0000' (27)
          'D12', # expected '12.0000' (12), got '13.0000' (13)
          'B13', # expected '5.0000' (5), got '4.0000' (4)
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
  rspec.include_context 'datalab multiple projects apr', include_shared: true
end
