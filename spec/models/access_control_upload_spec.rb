require 'rails_helper'

RSpec.describe AccessControlUpload, type: :model do
  let!(:access_control_upload) { create :access_control_upload }

  let!(:ds1) { create :source_data_source, id: 1 }
  let!(:o1) { create :hud_organization, data_source_id: ds1.id }
  let!(:p1) { create :hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let!(:p_coc1) { create :hud_project_coc, data_source_id: ds1.id, ProjectID: p1.ProjectID, CoCCode: 'XX-500' }
  let!(:p_group) { create :project_group, name: 'Additional XX-500 Projects' }

  before(:all) do
    GrdaWarehouse::Utility.clear!
  end
  describe 'importing' do
    it 'has attachment' do
      expect(access_control_upload.file).to be_present
    end
    it 'processes upload' do
      access_control_upload.pre_process!
      aggregate_failures do
        expect(access_control_upload.datasets.count).to eq(6)
        expect(access_control_upload.users.count).to eq(1)
        expect(access_control_upload.roles.count).to eq(2)
        expect(access_control_upload.collections.count).to eq(3)
        expect(access_control_upload.access_controls.count).to eq(3)
        # No cohorts, so we have some errors to check for
        expect(access_control_upload.collections.detect { |c| c['name'] == 'Care Coordination Cohorts' }['cohorts'].select { |c| c['found'] == false }.count).to eq(2)
      end
    end
    it 'imports data' do
      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      access_control_upload.pre_process!
      aggregate_failures do
        expect do
          access_control_upload.import!
        end.to change(User, :count).by(1)
        # These all get imported in the expect block
        expect(Role.pluck(:name)).to include('Care Coordinators', 'Report Runners')
        expect(AccessControl.not_system.count).to eq(3)
        expect(Collection.not_system.count).to eq(3)
        # Since we didn't make the cohorts, confirm, the cohort collection is empty
        expect(Collection.find_by_name('Care Coordination Cohorts').cohorts.count).to eq(0)
        expect(Collection.find_by_name('XX-500 Projects').coc_codes).to eq(['XX-500'])
        expect(Collection.find_by_name('XX-500 Projects').project_access_groups.count).to eq(1)
        expect(Collection.find_by_name('Approved Reports').reports.count).to eq(2)
      end
    end
  end
end
