require 'rails_helper'

RSpec.describe GrdaWarehouse::ProjectGroup, type: :model do
  let!(:ds) { create :data_source_fixed_id }
  let!(:project1) { create :grda_warehouse_hud_project, ProjectID: 958 }
  let!(:project2) { create :grda_warehouse_hud_project, ProjectID: 882 }
  let!(:project3) { create :grda_warehouse_hud_project, ProjectID: 240 }

  describe 'Initial import' do
    before do
      file = Rack::Test::UploadedFile.new('spec/fixtures/files/project_groups/project_group_import.xlsx', 'application/xlsx')
      GrdaWarehouse::ProjectGroup.import_csv(file)
    end
    it 'creates 2 project groups' do
      expect(GrdaWarehouse::ProjectGroup.count).to eq 2
    end
    it 'adds 3 projects to each group (ignoring bad data)' do
      expect(GrdaWarehouse::ProjectGroup.all.map { |pg| pg.projects.count }).to eq [3, 3]
    end

    describe 'After second import' do
      before do
        file = Rack::Test::UploadedFile.new('spec/fixtures/files/project_groups/project_group_import_second.xlsx', 'application/xlsx')
        GrdaWarehouse::ProjectGroup.import_csv(file)
      end

      it 'the first project group has 2 projects' do
        expect(GrdaWarehouse::ProjectGroup.find_by(name: 'Sample Project Group').projects.count).to eq 2
      end

      it 'the second project group still has 3 projects' do
        expect(GrdaWarehouse::ProjectGroup.find_by(name: 'Second Sample Project Group').projects.count).to eq 3
      end
    end
  end
end
