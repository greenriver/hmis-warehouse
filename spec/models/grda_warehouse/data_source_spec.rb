require 'rails_helper'

model = GrdaWarehouse::DataSource
RSpec.describe model, type: :model do
  # set up hierarchy like so
  #
  # data source:       ds1            ds2
  #                  /     \        /    \
  # organization:   o1     o2      o3    o4
  #                / \     /\     / \   /  \
  # project:     p1  p2  p3 p4  p5  p6 p7  p8

  let!(:admin_role) { create :admin_role }
  let!(:can_view_projects) { create :role, can_view_projects: true }

  let!(:user) { create :acl_user }

  let!(:ds1) { create :source_data_source, id: 1 }
  let!(:ds2) { create :source_data_source, id: 2 }

  let!(:o1) { create :hud_organization, data_source_id: ds1.id }
  let!(:o2) { create :hud_organization, data_source_id: ds1.id }
  let!(:o3) { create :hud_organization, data_source_id: ds2.id }
  let!(:o4) { create :hud_organization, data_source_id: ds2.id }

  let!(:p1) { create :hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let!(:p2) { create :hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let!(:p3) { create :hud_project, data_source_id: ds1.id, OrganizationID: o2.OrganizationID }
  let!(:p4) { create :hud_project, data_source_id: ds1.id, OrganizationID: o2.OrganizationID }
  let!(:p5) { create :hud_project, data_source_id: ds2.id, OrganizationID: o3.OrganizationID }
  let!(:p6) { create :hud_project, data_source_id: ds2.id, OrganizationID: o3.OrganizationID }
  let!(:p7) { create :hud_project, data_source_id: ds2.id, OrganizationID: o4.OrganizationID }
  let!(:p8) { create :hud_project, data_source_id: ds2.id, OrganizationID: o4.OrganizationID }

  let!(:pcoc1) { create :hud_project_coc, data_source_id: ds1.id, ProjectID: p1.ProjectID, CoCCode: 'XX-500' }
  let!(:pcoc2) { create :hud_project_coc, data_source_id: ds2.id, ProjectID: p5.ProjectID, CoCCode: 'XX-501' }

  let!(:pg1) { create :project_access_group, projects: [p1] }
  let!(:pg2) { create :project_access_group, projects: [p1, p5] }

  let!(:empty_collection) { create :collection }

  user_ids = ->(user) { model.viewable_by(user, permission: :can_view_projects).pluck(:id).sort }
  ids = ->(*sources) { sources.map(&:id).sort }

  describe 'scopes' do
    describe 'viewability' do
      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'admin user' do
        before do
          Collection.maintain_system_groups
          setup_access_control(user, admin_role, Collection.system_collection(:data_sources))
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees both' do
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to project' do
        it 'sees ds1' do
          empty_collection.set_viewables({ projects: [p1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ projects: [p1.id, p5.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to organization' do
        it 'sees ds1' do
          empty_collection.set_viewables({ organizations: [o1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ organizations: [o1.id, o3.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to data source' do
        it 'sees ds1' do
          empty_collection.set_viewables({ data_sources: [ds1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ data_sources: [ds1.id, ds2.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to projet group' do
        it 'sees ds1' do
          empty_collection.set_viewables({ project_access_groups: [pg1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ project_access_groups: [pg1.id, pg2.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to CoC XX-500' do
        it 'sees ds1' do
          empty_collection.update(coc_codes: ['XX-500'])
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.update(coc_codes: ['XX-500', 'XX-501'])
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end
    end
  end

  describe 'importer' do
    let!(:imports) { create_list :grda_warehouse_upload, 12, data_source_id: ds1.id, user_id: User.system_user.id, percent_complete: 100, completed_at: 2.years.ago }

    describe 'when expecting one file' do
      let!(:import_config) { create :grda_warehouse_hmis_import_config, file_count: 1, data_source_id: ds1.id }
      it 'is not stalled when there are no prior imports in the past 6 months' do
        expect(ds1.stalled_date).to eq(nil)
      end

      it 'is stalled when the last import was over 24 hours ago' do
        imports.each.with_index { |import, i| import.update(completed_at: (i + 1).days.ago - 2.minutes) }
        expect(ds1.stalled_date).to_not eq(nil)
      end

      it 'is not stalled when there was an import yesterday' do
        imports.each.with_index { |import, i| import.update(completed_at: i.days.ago + 2.minutes) }
        expect(ds1.stalled_date).to eq(nil)
      end

      it 'is stalled when the last import was 26 hours ago' do
        imports.each.with_index do |import, i|
          time = i.days.ago - 26.hours
          import.update(completed_at: time)
        end
        expect(ds1.stalled_date).to_not eq(nil)
      end
    end

    describe 'when expecting multiple file' do
      let!(:import_config) { create :grda_warehouse_hmis_import_config, file_count: 3, data_source_id: ds1.id }
      it 'is not stalled when there are no prior imports in the past 6 months' do
        expect(ds1.stalled_date).to eq(nil)
      end

      it 'is stalled when there was a partial import yesterday' do
        # Move one file into the expected range
        imports.each.with_index { |import, i| import.update(completed_at: i.days.ago) }
        expect(ds1.stalled_date).to_not eq(nil)
      end

      it 'is stalled when there was a full import recently, but nothing in the past 24 hours' do
        imports.first(3).each { |import| import.update(completed_at: 25.hours.ago) }
        expect(ds1.stalled_date).to_not eq(nil)
      end

      it 'is not stalled when there was a full import within the last 24 hours' do
        imports.first(3).each { |import| import.update(completed_at: 23.hours.ago) }
        expect(ds1.stalled_date).to eq(nil)
      end
    end
  end
end
