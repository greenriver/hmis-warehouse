###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'path organization r', shared_context: :metadata do
  describe 'Datalab 2024 PATH - Organization R' do
    let(:results_dir) { 'path/path_organization_r' }
    before(:all) do
      generator = HudPathReport::Generators::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization R - SSO', 'Organization R - SO']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    # Pending: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recgCQFAPQ183oDbJ
    # Pending: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rechv4vnjzExZMhVg
    xit 'Q8-Q16' do
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

    # Pending: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rechv4vnjzExZMhVg
    #
    # Previous: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recibeszBDplTEBFJ
    # 596228 - missing? DataLab is using the earlier enrollment, why? - later is active, but not enrolled
    # 844241 - entry date 8/17/2022, is active because of DateOfEngagement

    xit 'Q19-Q24' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19-Q24',
      )
    end

    # Pending: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rechv4vnjzExZMhVg
    #
    # Previous: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recPVamjYOzWWTx5U
    xit 'Q25' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25',
      )
    end

    # Pending: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rechv4vnjzExZMhVg
    #
    # Previous: https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recUam4bP8a5eJGSK
    xit 'Q26' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26',
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'path organization r', include_shared: true
end
