###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  describe 'When importing' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/project_test_files',
        version: '2020',
        run_jobs: true,
      )
    end

    it 'the database will have five funders, four inventories and five project Cocs' do
      expect(GrdaWarehouse::Hud::Funder.count).to eq(5)
      expect(GrdaWarehouse::Hud::Inventory.count).to eq(4)
      expect(GrdaWarehouse::Hud::ProjectCoc.count).to eq(5)
    end

    describe 'when importing after adding manual records' do
      before(:all) do
        project = GrdaWarehouse::Hud::Project.first
        funder = GrdaWarehouse::Hud::Funder.first.dup
        funder.manual_entry = true
        funder.FunderID = 'm-5'
        funder.ProjectID = project.ProjectID
        funder.save
        inventory = GrdaWarehouse::Hud::Inventory.first.dup
        inventory.manual_entry = true
        inventory.InventoryID = 'm-5'
        inventory.ProjectID = project.ProjectID
        inventory.save
        project_coc = GrdaWarehouse::Hud::ProjectCoc.first.dup
        project_coc.manual_entry = true
        project_coc.ProjectCoCID = 'm-5'
        project_coc.ProjectID = project.ProjectID
        project_coc.save
        import_hmis_csv_fixture(
          'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/project_test_files',
          version: '2020',
          run_jobs: true,
        )
      end
      it 'does not delete the manual Funder, Inventory or ProjectCoc records' do
        expect(GrdaWarehouse::Hud::Funder.count).to eq(6)
        expect(GrdaWarehouse::Hud::Funder.where(FunderID: 'm-5').count).to eq(1)
        expect(GrdaWarehouse::Hud::Inventory.count).to eq(5)
        expect(GrdaWarehouse::Hud::Inventory.where(InventoryID: 'm-5').count).to eq(1)
        expect(GrdaWarehouse::Hud::ProjectCoc.count).to eq(6)
        expect(GrdaWarehouse::Hud::ProjectCoc.where(ProjectCoCID: 'm-5').count).to eq(1)
      end
    end
  end
end
