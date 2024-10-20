###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'path organization q', shared_context: :metadata do
  describe 'Datalab 2024 PATH - Organization Q' do
    let(:results_dir) { 'path/path_organization_q' }
    before(:all) do
      generator = HudPathReport::Generators::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization Q - SSO']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    # Previous (124): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recu6GJJUDn94R9j4
    # Previous (125): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recda7O3T90PIwadz
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
      )
    end

    it 'Q18' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q18',
      )
    end

    it 'Q19-Q24' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19-Q24',
      )
    end

    # Previous (126): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recPVamjYOzWWTx5U
    it 'Q25' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25',
      )
    end

    # Previous (127): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recUam4bP8a5eJGSK
    it 'Q26' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26',
        skip: [
          'C89', # Pending (134): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/reckiuBz8DwhFmQ8n
          'C90',
          'C91', # Pending (133): https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recSJ3fb7EBfkrakM
        ],
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'path organization q', include_shared: true
end
