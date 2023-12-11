###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    it 'Q8-Q16' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8-Q16',
        skip: [
          'B6', # TOOD
          # Pending: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recu6GJJUDn94R9j4 and https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recda7O3T90PIwadz
          'B7', # 677140 May 9, 2022 (2) and 692358 Aug 22, 2022 (2) counted twice on one day
        ],
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

    # TODO
    it 'Q19-Q24' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19-Q24',
      )
    end

    # Pending: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recPVamjYOzWWTx5U
    xit 'Q25' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25',
      )
    end

    # Pending: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recUam4bP8a5eJGSK
    xit 'Q26' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'path organization q', include_shared: true
end
