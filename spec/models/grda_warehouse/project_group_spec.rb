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

  describe '#system_collection' do
    let(:user) { create(:user) }
    let(:user_2) { create(:user) }
    let(:project_group) { create(:project_group, name: 'Old Name') }

    it 'returns the same system collection when the name changes and replace_access is called' do
      original_collection = project_group.system_collection
      original_viewable_user_group = project_group.system_viewable_user_group
      original_editable_user_group = project_group.system_editable_user_group
      project_group.replace_access(user, scope: :editor)

      # Verify the original collection name matches ProjectGroup's name
      expect(original_collection.name).to eq('Old Name')

      # This is a regression catch, historically, changing the project name
      # would cause a new collection and user_group to be created
      # Update the ProjectGroup's name
      project_group.update!(name: 'New Name')

      # Calling replace_access (which triggers the entity access logic)
      project_group.replace_access([user, user_2], scope: :editor)

      # Force re-calculation
      project_group.instance_variable_set(:@system_collection, nil)
      project_group.instance_variable_set(:@system_viewable_user_group, nil)
      project_group.instance_variable_set(:@system_editable_user_group, nil)
      updated_collection = project_group.system_collection
      updated_viewable_user_group = project_group.system_viewable_user_group
      updated_editable_user_group = project_group.system_editable_user_group

      # Confirm the IDs have not changed (i.e., it's still the same record)
      expect(updated_collection.id).to eq(original_collection.id)
      expect(updated_viewable_user_group.id).to eq(original_viewable_user_group.id)
      expect(updated_editable_user_group.id).to eq(original_editable_user_group.id)
      # Confirm the collection's name has been updated to match the new ProjectGroup name
      expect(updated_collection.name).to eq('New Name')
    end
  end
end
