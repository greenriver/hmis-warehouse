###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Prepend Project IDs', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    it 'Has 1 project' do
      expect(GrdaWarehouse::Hud::Project.count).to eq(1)
    end

    it 'Project Name is Test Project' do
      expect(GrdaWarehouse::Hud::Project.first.ProjectName).to eq('Test Project')
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    it 'Has 1 project' do
      expect(GrdaWarehouse::Hud::Project.count).to eq(1)
    end

    it 'Project Name is (PROJECT) Test Project' do
      expect(GrdaWarehouse::Hud::Project.first.ProjectName).to eq('(PROJECT) Test Project')
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    data_source = if with_cleanup
      create(:prepend_project_ids)
    else
      create(:dont_cleanup_ds)
    end

    import_hmis_csv_fixture(
      'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/cleanup_move_ins',
      data_source: data_source,
      version: '2020',
      run_jobs: false,
    )
  end
end
