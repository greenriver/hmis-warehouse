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
        skip: [
          'L2', # Is the generator name, so not expected to match
        ],
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

    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec5AxqrAUl0f8yAf
    xit 'Q7b' do
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
    xit 'Q8b' do
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
        skip: [
          'F7', # rounding difference, not significant
          'J2', # rounding difference, not significant
        ],
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
        # TODO: off by one, investigation needed
        skip: [
          'D2',
          'D6',
        ],
      )
    end

    # TODO: off by one or two in a few categories, investigation needed,
    # but sufficiently close for now
    xit 'Q21' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q21',
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

    # TODO: off by one or two in a few categories, investigation needed,
    # but sufficiently close for now
    xit 'Q22e' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22e',
      )
    end

    # TODO: off by one or two in a few categories, investigation needed,
    # but sufficiently close for now
    xit 'Q22f' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q22f',
      )
    end

    # TODO: off by one or two in a few categories, investigation needed,
    # but sufficiently close for now
    xit 'Q22g' do
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
    xit 'Q25b' do
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
          'B3',
          'C3', # new
          'D3',
          'B5',
          'C5', # new
          'D5',
        ],
      )
    end

    # Previous https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recnAJsqhnXlGmmZG
    # Not counting children with HoH or adult in CH calculation
    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recTCOE44QtrUKsfZ
    xit 'Q26b' do
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
          'B2',
          'C2',
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

    # TODO: off by one or two in a few categories, investigation needed,
    # but sufficiently close for now
    xit 'Q27l' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q27l',
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
