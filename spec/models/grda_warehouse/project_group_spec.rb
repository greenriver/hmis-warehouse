###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ProjectGroup, type: :model do
  let!(:ds) { create :data_source_fixed_id }
  let!(:project1) { create :grda_warehouse_hud_project, ProjectID: 958 }
  let!(:project2) { create :grda_warehouse_hud_project, ProjectID: 882 }
  let!(:project3) { create :grda_warehouse_hud_project, ProjectID: 240 }

  describe 'viewable_by followed by a merge on project group id' do
    let!(:user) { create :acl_user }
    let!(:report_role) { create :assigned_report_viewer }
    let!(:collection) { create :collection }
    let!(:visible_group) { create :project_group }
    let!(:invisible_group) { create :project_group }

    before do
      collection.set_viewables({ project_groups: [visible_group.id] })
      setup_access_control(user, report_role, collection)
    end

    it 'does not widen to an invisible project group' do
      scope = described_class.viewable_by(user).merge(described_class.where(id: invisible_group.id))
      expect(scope.pluck(:id)).to be_empty
    end

    it 'intersects with the merged ids' do
      scope = described_class.viewable_by(user).merge(described_class.where(id: [visible_group.id, invisible_group.id]))
      expect(scope.pluck(:id)).to eq [visible_group.id]
    end
  end

  describe 'maintain_projects!' do
    let!(:organization) { create :grda_warehouse_hud_organization }
    let!(:open_project) { create :grda_warehouse_hud_project, OrganizationID: organization.OrganizationID }
    let!(:confidential_project) do
      create :grda_warehouse_hud_project, OrganizationID: organization.OrganizationID, confidential: true
    end

    # Confidential projects are left out by SystemProjectHudFilter#all_project_scope, not by
    # the system user's permissions, so the result is the same whatever the system user can see
    shared_examples 'leaves confidential projects out of broad selections' do
      it 'leaves confidential projects out of an organization selection' do
        group = create :project_group, options: { organization_ids: [organization.id] }
        group.maintain_projects!

        expect(group.projects.pluck(:id)).to eq [open_project.id]
      end

      it 'leaves confidential projects out of a data source selection' do
        group = create :project_group, options: { data_source_ids: [ds.id] }
        group.maintain_projects!

        expect(group.projects.pluck(:id)).to include open_project.id
        expect(group.projects.pluck(:id)).not_to include confidential_project.id
      end

      it 'leaves confidential projects out of a project type selection' do
        open_project.update!(ProjectType: 1)
        confidential_project.update!(ProjectType: 1)
        group = create :project_group, options: { project_type_numbers: [1] }
        group.maintain_projects!

        expect(group.projects.pluck(:id)).to include open_project.id
        expect(group.projects.pluck(:id)).not_to include confidential_project.id
      end
    end

    context 'when the system user has no project access' do
      include_examples 'leaves confidential projects out of broad selections'
    end

    context 'when the system user can report on every project, including confidential ones' do
      before do
        system_user = User.setup_system_user
        role = create(
          :assigned_report_viewer,
          can_view_projects: true,
          can_report_on_confidential_projects: true,
        )
        all_projects = GrdaWarehouse::Hud::Project.all.to_a
        mode = system_user.using_acls? ? :acl : :legacy
        grant_project_access(system_user, role, all_projects, mode: mode)

        reportable_projects = GrdaWarehouse::Hud::Project.viewable_by(
          system_user,
          permission: :can_view_assigned_reports,
        )
        expect(reportable_projects.pluck(:id)).to include confidential_project.id
      end

      include_examples 'leaves confidential projects out of broad selections'
    end

    it 'keeps confidential projects picked by name' do
      group = create :project_group, options: { project_ids: [open_project.id, confidential_project.id] }
      group.maintain_projects!

      expect(group.projects.pluck(:id)).to contain_exactly(open_project.id, confidential_project.id)
    end

    it 'adds newly matching non-confidential projects during hourly maintenance' do
      open_project.update!(ProjectType: 1)
      group = create :project_group, options: { project_type_numbers: [1] }
      group.maintain_projects!
      expect(group.projects.pluck(:id)).to eq [open_project.id]

      new_open_project = create(
        :grda_warehouse_hud_project,
        ProjectType: 1,
        OrganizationID: organization.OrganizationID,
      )
      new_confidential_project = create(
        :grda_warehouse_hud_project,
        ProjectType: 1,
        OrganizationID: organization.OrganizationID,
        confidential: true,
      )
      described_class.maintain_project_lists!

      group_project_ids = group.reload.projects.pluck(:id)
      expect(group_project_ids).to contain_exactly(open_project.id, new_open_project.id)
      expect(group_project_ids).not_to include new_confidential_project.id
    end

    it 'keeps directly listed projects when the system user has no project access yet' do
      group = create :project_group, options: { project_ids: [open_project.id] }
      # e.g. a new data source before the delayed system group maintenance has run
      GrdaWarehouse::GroupViewableEntity.delete_all
      expect(GrdaWarehouse::Hud::Project.viewable_by(User.setup_system_user, permission: :can_view_assigned_reports)).to be_empty

      group.maintain_projects!

      expect(group.projects.pluck(:id)).to eq [open_project.id]
    end
  end

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

  describe '#markdown_notes' do
    subject(:group) { build(:project_group, skip_maintain_system_group: true) }

    it 'renders markdown to html' do
      group.notes = '**bold**'
      expect(group.markdown_notes).to include('<strong>bold</strong>')
    end

    it 'returns empty string for blank notes' do
      group.notes = nil
      expect(group.markdown_notes).to eq('')
      group.notes = ''
      expect(group.markdown_notes).to eq('')
    end

    it 'strips script tags to prevent XSS' do
      group.notes = '<script>alert("xss")</script>'
      # filter_html removes the tag; text content remains as harmless plain text
      expect(group.markdown_notes).not_to include('<script>')
      expect(group.markdown_notes).not_to include('&lt;script&gt;')
    end

    it 'strips raw html tags' do
      group.notes = '<b>bold</b>'
      expect(group.markdown_notes).not_to include('<b>')
      expect(group.markdown_notes).not_to include('&lt;b&gt;')
    end

    it 'drops javascript: links' do
      group.notes = '[click me](javascript:alert(1))'
      expect(group.markdown_notes).not_to include('href="javascript:')
    end
  end
end
