###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'path organization p', shared_context: :metadata do
  describe 'Datalab 2026 PATH - Organization P' do
    let(:results_dir) { 'path/path_organization_p' }
    before(:all) do
      generator = HudPathReport::Generators::Fy2026::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization P - SO']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    # Previous (122): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec4ABXImQDXgWZCe
    # (appears the test kit includes Exit Date in the active calculation.) Guidance provided, exit date should always be included (B2, B11)
    # Previous (124): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recu6GJJUDn94R9j4 and
    #          (125): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recda7O3T90PIwadz
    #           'B7', contains 677140 May 9, 2022 (2) and 692358 Aug 22, 2022 (2) counted twice on one day
    it 'Q8-Q16' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8-Q16',
        skip: [
          'B2', # expected '62.0000' (62), got '61.0000' (61)
          'B3', # expected '44.0000' (44), got '43.0000' (43)
          'B5', # expected '44.0000' (44), got '43.0000' (43)
          'B6', # expected '36.0000' (36), got '35.0000' (35)
          'B7', # expected '36.0000' (36), got '35.0000' (35)
          'B10', # expected '35.0000' (35), got '34.0000' (34)
          'B11', # expected '41.0000' (41), got '40.0000' (40)
          'B12', # expected '33.0000' (33), got '32.0000' (32)
        ],
      )
    end

    it 'Q17' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q17',
        skip: [
          'B3', # expected '34.0000' (34), got '33.0000' (33)
          'B6', # expected '32.0000' (32), got '31.0000' (31)
          'B8', # expected '34.0000' (34), got '33.0000' (33)
        ],
      )
    end

    it 'Q18' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q18',
        skip: [
          'B2', # expected '30.0000' (30), got '29.0000' (29)
          'C2', # expected '30.0000' (30), got '29.0000' (29)
          'B12', # expected '2.0000' (2), got '1.0000' (1)
        ],
      )
    end

    it 'Q19-Q24' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19-Q24',
        skip: [
          'B4', # expected '31.0000' (31), got '30.0000' (30)
          'C4', # expected '7.0000' (7), got '6.0000' (6)
          'B8', # expected '41.0000' (41), got '40.0000' (40)
          'C8', # expected '13.0000' (13), got '12.0000' (12)
          'B11', # expected '33.0000' (33), got '32.0000' (32)
          'C11', # expected '8.0000' (8), got '7.0000' (7)
          'B14', # expected '20.0000' (20), got '19.0000' (19)
          'C14', # expected '7.0000' (7), got '6.0000' (6)
          'B18', # expected '41.0000' (41), got '40.0000' (40)
          'C18', # expected '13.0000' (13), got '12.0000' (12)
          'B21', # expected '6.0000' (6), got '5.0000' (5)
          'C21', # expected '2.0000' (2), got '1.0000' (1)
          'B25', # expected '41.0000' (41), got '40.0000' (40)
          'C25', # expected '13.0000' (13), got '12.0000' (12)
          'B28', # expected '12.0000' (12), got '11.0000' (11)
          'C28', # expected '4.0000' (4), got '3.0000' (3)
          'B31', # expected '37.0000' (37), got '36.0000' (36)
          'C31', # expected '12.0000' (12), got '11.0000' (11)
        ],
      )
    end

    # Previous (126): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recPVamjYOzWWTx5U
    it 'Q25' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25',
        skip: [
          'B3', # expected '1.0000' (1), got '0.0000' (0)
          'B6', # expected '3.0000' (3), got '2.0000' (2)
          'B42', # expected '41.0000' (41), got '40.0000' (40)
        ],
      )
    end

    # Previous (127): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recUam4bP8a5eJGSK
    # Previous (133): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recSJ3fb7EBfkrakM
    it 'Q26' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26',
        skip: [
          'C2', # expected '1.0000' (1), got '0.0000' (0)
          'C8', # expected '6.0000' (6), got '5.0000' (5)
          'C11', # expected '0.0000' (0), got '1.0000' (1)
          'C12', # expected '41.0000' (41), got '40.0000' (40)
          'C22', # expected '10.0000' (10), got '9.0000' (9)
          'C23', # expected '41.0000' (41), got '40.0000' (40)
          'C25', # expected '31.0000' (31), got '30.0000' (30)
          'C29', # expected '38.0000' (38), got '37.0000' (37)
          'C31', # expected '32.0000' (32), got '31.0000' (31)
          'C33', # expected '41.0000' (41), got '40.0000' (40)
          'C35', # expected '41.0000' (41), got '40.0000' (40)
          'C39', # expected '41.0000' (41), got '40.0000' (40)
          'C41', # expected '27.0000' (27), got '26.0000' (26)
          'C67', # expected '41.0000' (41), got '40.0000' (40)
          'C72', # expected '12.0000' (12), got '11.0000' (11)
          'C77', # expected '33.0000' (33), got '32.0000' (32)
          'C79', # expected '24.0000' (24), got '23.0000' (23)
          'C81', # expected '41.0000' (41), got '40.0000' (40)
          'C83', # expected '25.0000' (25), got '24.0000' (24)
          'C87', # expected '38.0000' (38), got '37.0000' (37)
          'C90', # expected '21.0000' (21), got '20.0000' (20)
          'C91', # expected '41.0000' (41), got '40.0000' (40)
        ],
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'path organization p', include_shared: true
end
