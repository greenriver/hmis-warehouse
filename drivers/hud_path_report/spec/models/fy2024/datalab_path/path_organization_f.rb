###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'path organization f', shared_context: :metadata do
  describe 'Datalab 2024 PATH - Organization F' do
    let(:results_dir) { 'path/path_organization_f' }
    before(:all) do
      generator = HudPathReport::Generators::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization F - SO']).pluck(:id)
      run(generator, project_ids_filter(project_ids))
    end

    it 'Q8-Q16' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q8-Q16',
        # TODO the following don't currently match, but do produce data
        # Prior https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec4ABXImQDXgWZCe (appears the test kit includes Exit Date in the active calculation.) Guidance provided, exit date should always be included (B2, B11)
        skip: [
          # Pending:
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

    it 'Q19-Q24' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q19-Q24',
      )
    end

    it 'Q25' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q25',
        # TODO the following don't currently match, but do produce data
        skip: [
          'B10',
          'B14',
          'B28',
          'B29',
          'B32',
          'B34',
          'B39',
          'B40',
          'B41',
          'B42',
        ],
      )
    end

    xit 'Q26' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: 'Q26',
        # TODO the following don't currently match, but do produce data
        # skip: [
        #   'C2',
        #   'C3',
        #   'C12',
        #   'C13',
        #   'C15',
        #   'C16',
        #   'C17',
        #   'C18',
        #   'C19',
        #   'C23',
        #   'C24',
        #   'C25',
        #   'C26',
        #   'C30',
        #   'C34',
        #   'C35',
        #   'C36',
        #   'C40',
        #   'C41',
        #   'C42',
        #   'C44',
        #   'C45',
        #   'C46',
        #   'C49',
        #   '...',
        # ],
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'path organization f', include_shared: true
end
