require 'rails_helper'

model = GrdaWarehouse::Hud::Project

RSpec.describe model, type: :model do
  # set up hierarchy like so
  #
  # data source:       ds1            ds2
  #                  /     \        /    \
  # organization:   o1     o2      o3    o4
  #                / \     /\     / \   /  \
  # project:     p1  p2  p3 p4  p5  p6 p7  p8
  #               |   |      |   |      |   |
  # project coc: pc1 pc2    pc3 pc4    pc5 pc6

  let!(:admin_role) { create :admin_role }
  let!(:can_view_confidential_projects) { create :can_view_confidential_projects }
  let!(:can_report_on_confidential_projects) { create :can_report_on_confidential_projects, can_report_on_confidential_projects: true }

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

  let!(:pc1) { create :hud_project_coc, data_source_id: ds1.id, ProjectID: p1.ProjectID, CoCCode: 'foo' }
  let!(:pc2) { create :hud_project_coc, data_source_id: ds1.id, ProjectID: p2.ProjectID, CoCCode: 'foo' }
  let!(:pc3) { create :hud_project_coc, data_source_id: ds1.id, ProjectID: p4.ProjectID, CoCCode: 'foo' }
  let!(:pc4) { create :hud_project_coc, data_source_id: ds2.id, ProjectID: p5.ProjectID, CoCCode: 'foo' }
  let!(:pc5) { create :hud_project_coc, data_source_id: ds2.id, ProjectID: p7.ProjectID, CoCCode: 'bar' }
  let!(:pc6) { create :hud_project_coc, data_source_id: ds2.id, ProjectID: p8.ProjectID, CoCCode: 'bar' }

  let!(:pg1) { create :project_access_group, projects: [p1] }

  let!(:can_view_projects_role) { create :role, can_view_projects: true }
  let!(:no_data_source_collection) { create :collection }

  u = ->(user) do
    if model == GrdaWarehouse::Hud::Project
      model.viewable_by(user, confidential_scope_limiter: :all, permission: :can_view_projects).pluck(:id).sort
    else
      model.viewable_by(user).pluck(:id).sort
    end
  end

  p = ->(*projects) { projects.map(&:id).sort }

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
        it 'sees all 8' do
          expect(u[user]).to eq p[p1, p2, p3, p4, p5, p6, p7, p8]
        end
      end

      describe 'user assigned to project' do
        before do
          no_data_source_collection.set_viewables({ projects: [p1.id] })
          setup_access_control(user, can_view_projects_role, no_data_source_collection)
        end
        it 'sees p1' do
          expect(u[user]).to eq p[p1]
        end
      end

      describe 'user assigned to organization' do
        before do
          no_data_source_collection.set_viewables({ organizations: [o1.id] })
          setup_access_control(user, can_view_projects_role, no_data_source_collection)
        end
        it 'sees p1 and p2' do
          expect(u[user]).to eq p[p1, p2]
        end
      end

      describe 'user assigned to data source' do
        before do
          no_data_source_collection.set_viewables({ data_sources: [ds1.id] })
          setup_access_control(user, can_view_projects_role, no_data_source_collection)
        end
        it 'sees p1 - p4' do
          expect(u[user]).to eq p[p1, p2, p3, p4]
        end
      end

      describe 'user assigned to coc foo' do
        before do
          no_data_source_collection.update(coc_codes: ['foo'])
          setup_access_control(user, can_view_projects_role, no_data_source_collection)
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees p1, p2, p4, p5' do
          expect(u[user]).to eq p[p1, p2, p4, p5]
        end
      end

      describe 'user assigned to coc bar' do
        before do
          no_data_source_collection.update(coc_codes: ['bar'])
          setup_access_control(user, can_view_projects_role, no_data_source_collection)
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees p7 and p8' do
          expect(u[user]).to eq p[p7, p8]
        end
      end

      describe 'user given project access group' do
        before do
          no_data_source_collection.set_viewables({ project_access_groups: [pg1.id] })
          setup_access_control(user, can_view_projects_role, no_data_source_collection)
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees p1 but not p2' do
          expect(u[user]).to eq p[p1]
          expect(u[user]).to_not include p2
        end
      end
    end

    describe 'confidentiality' do
      before(:each) do
        p1.update(confidential: true) # project in CoC 'foo'
        p8.update(confidential: true) # project in CoC 'bar'
        o2.update(confidential: true)
      end

      describe 'projects in a confidential organization' do
        it 'are considered confidential' do
          expect(p3.confidential).to be true
          expect(p3.confidential?).to be true
        end
      end

      describe 'project scopes' do
        it 'include confidential projects' do
          confidential_scope = GrdaWarehouse::Hud::Project.confidential
          expect(confidential_scope.pluck(:id).sort).to eq p[p1, p3, p4, p8]
        end

        it 'exclude confidential projects' do
          non_confidential_scope = GrdaWarehouse::Hud::Project.non_confidential
          expect(non_confidential_scope.pluck(:id).sort).to eq p[p2, p5, p6, p7]
        end
      end

      describe 'user without permission to view confidential project names' do
        describe 'assigned to confidential project' do
          before do
            # p1 # confidential project
            # p2 # non-confidential project
            no_data_source_collection.set_viewables({ projects: [p1.id, p2.id] })
            setup_access_control(user, can_view_projects_role, no_data_source_collection)
          end
          it 'sees p1 confidentialized' do
            expect(u[user]).to eq p[p1, p2]
            expect(p1.name(user).downcase).to include 'confidential'
          end
          it 'does not see p1 in options for select' do
            options = GrdaWarehouse::Hud::Project.options_for_select(user: user)
            expect(options.keys.size).to eq 1
            project_ids = options.values.flatten(1).map(&:second)
            expect(project_ids).to eq [p2.id]
          end

          it 'does not include p1 in viewable_by' do
            expect(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_projects).pluck(:id)).to_not include p1.id
          end
        end

        describe 'assigned to confidential organization' do
          before do
            # o2 # confidential organization
            # p2 # non-confidential project
            no_data_source_collection.set_viewables({ projects: [p2.id], organizations: [o2.id] })
            setup_access_control(user, can_view_projects_role, no_data_source_collection)
          end
          it 'sees p3 and p4 confidentialized' do
            expect(u[user]).to eq p[p2, p3, p4]
            expect(p3.name(user).downcase).to include 'confidential'
            expect(p4.name(user).downcase).to include 'confidential'
          end

          it 'does not see p3 and p4 in options for select' do
            options = GrdaWarehouse::Hud::Project.options_for_select(user: user)
            expect(options.keys.size).to eq 1
            project_ids = options.values.flatten(1).map(&:second)
            expect(project_ids).to eq [p2.id]
          end

          it 'does not include p3 or p4 in viewable_by' do
            expect(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_projects).pluck(:id)).to_not include p3.id
            expect(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_projects).pluck(:id)).to_not include p4.id
          end
        end

        describe 'assigned to coc foo' do
          before do
            no_data_source_collection.update(coc_codes: ['foo'])
            setup_access_control(user, can_view_projects_role, no_data_source_collection)
          end
          after do
            user.user_group_members.destroy_all
          end
          it 'sees p1 and p4 confidentialized' do
            expect(u[user]).to include(p1.id, p4.id)
            expect(p1.name(user).downcase).to include 'confidential'
            expect(p4.name(user).downcase).to include 'confidential'
          end
        end
      end

      describe 'user with permission to view confidential project names' do
        after do
          user.user_group_members.destroy_all
        end

        describe 'assigned to confidential project' do
          before do
            no_data_source_collection.set_viewables({ projects: [p1.id] })
            setup_access_control(user, can_view_confidential_projects, no_data_source_collection)
          end
          it 'sees p1 project name' do
            expect(u[user]).to eq p[p1]
            expect(p1.name(user).downcase).not_to include 'confidential'
          end

          it 'does not include p1 in viewable_by' do
            expect(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_projects).pluck(:id)).to_not include p1.id
          end
        end

        describe 'when given permission to report on confidential projects' do
          before do
            no_data_source_collection.set_viewables({ projects: [p1.id] })
            setup_access_control(user, can_report_on_confidential_projects, no_data_source_collection)
          end
          after do
            user.user_group_members.destroy_all
          end
          it 'does include p1 in viewable_by in report context, but no viewing' do
            expect(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_report_on_confidential_projects).pluck(:id)).to include p1.id
            expect(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_projects).pluck(:id)).to_not include p1.id
          end
        end

        describe 'assigned to confidential organization' do
          before do
            no_data_source_collection.set_viewables({ organizations: [o2.id] })
            setup_access_control(user, can_view_confidential_projects, no_data_source_collection)
          end
          it 'sees p3 and p4 project names' do
            expect(u[user]).to eq p[p3, p4]
            expect(p3.name(user).downcase).not_to include 'confidential'
            expect(p4.name(user).downcase).not_to include 'confidential'
          end
        end

        describe 'assigned to coc foo' do
          before do
            no_data_source_collection.update(coc_codes: ['foo'])
            setup_access_control(user, can_view_confidential_projects, no_data_source_collection)
          end
          after do
            user.user_group_members.destroy_all
          end
          it 'sees p1 and p4 project names' do
            expect(u[user]).to include(p1.id, p4.id)
            expect(p1.name(user).downcase).not_to include 'confidential'
            expect(p4.name(user).downcase).not_to include 'confidential'
          end
          it 'sees p8 confidentialized' do
            expect(u[user]).not_to include p8.id
            expect(p8.name(user).downcase).to include 'confidential'
          end
        end
      end
    end
  end
end
