###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'path organization v', shared_context: :metadata do
  describe 'Datalab 2026 PATH - Organization V' do
    let(:results_dir) { 'path/path_organization_v' }
    before(:all) do
      generator = HudPathReport::Generators::Fy2026::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization V - SO', 'Organization V - SO - 2', 'Organization V - SO - 3']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    # Previous (137): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recgCQFAPQ183oDbJ
    # Previous (138): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rechv4vnjzExZMhVg
    # Previous (136): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recIZVtmaHvrbA59N
    it 'Q8-Q16' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8-Q16',
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q17',
        skip: [
          'B3', # expected '86.0000' (86), got '87.0000' (87)
          'B8', # expected '86.0000' (86), got '87.0000' (87)
        ],
      )
    end

    it 'Q18' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q18',
        skip: [
          'B2', # expected '53.0000' (53), got '54.0000' (54)
        ],
      )
    end

    # Previous(138): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rechv4vnjzExZMhVg
    # Previous (128): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recibeszBDplTEBFJ
    # 596228 - missing? DataLab is using the earlier enrollment, why? - later is active, but not enrolled
    # 844241 - entry date 8/17/2022, is active because of DateOfEngagement

    it 'Q19-Q24' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19-Q24',
        skip: [
          'C4', # expected '39.0000' (39), got '40.0000' (40)
          'D4', # expected '31.0000' (31), got '30.0000' (30)
          'C8', # expected '81.0000' (81), got '82.0000' (82)
          'D8', # expected '63.0000' (63), got '62.0000' (62)
          'C11', # expected '49.0000' (49), got '50.0000' (50)
          'D11', # expected '38.0000' (38), got '37.0000' (37)
          'C13', # expected '43.0000' (43), got '44.0000' (44)
          'D13', # expected '36.0000' (36), got '35.0000' (35)
          'C18', # expected '81.0000' (81), got '82.0000' (82)
          'D18', # expected '63.0000' (63), got '62.0000' (62)
          'C20', # expected '72.0000' (72), got '73.0000' (73)
          'D20', # expected '51.0000' (51), got '50.0000' (50)
          'C25', # expected '81.0000' (81), got '82.0000' (82)
          'D25', # expected '63.0000' (63), got '62.0000' (62)
          'C27', # expected '66.0000' (66), got '67.0000' (67)
          'D27', # expected '48.0000' (48), got '47.0000' (47)
          'C31', # expected '67.0000' (67), got '68.0000' (68)
          'D31', # expected '57.0000' (57), got '56.0000' (56)
        ],
      )
    end

    # Previous (138): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rechv4vnjzExZMhVg
    # Previous (126): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recPVamjYOzWWTx5U
    it 'Q25' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25',
        skip: [
          'B34', # expected '55.0000' (55), got '56.0000' (56)
          'B40', # expected '56.0000' (56), got '57.0000' (57)
          'B41', # expected '63.0000' (63), got '62.0000' (62)
        ],
      )
    end

    # Previous (138): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rechv4vnjzExZMhVg
    # Previous (127): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recUam4bP8a5eJGSK
    # Previous (133): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recSJ3fb7EBfkrakM
    it 'Q26' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'path organization v', include_shared: true
end
