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

  let!(:user) { create :user }

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
  let!(:pc5) { create :hud_project_coc, data_source_id: ds2.id, ProjectID: p7.ProjectID, CoCCode: 'foo', hud_coc_code: 'bar' }
  let!(:pc6) { create :hud_project_coc, data_source_id: ds2.id, ProjectID: p8.ProjectID, hud_coc_code: 'bar' }

  u = ->(user) { model.viewable_by(user).pluck(:id).sort }
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
          user.roles << admin_role
          AccessGroup.maintain_system_groups
          user.access_groups = AccessGroup.all
        end
        after do
          user.roles = []
          user.access_groups = []
        end
        it 'sees all 8' do
          expect(u[user]).to eq p[p1, p2, p3, p4, p5, p6, p7, p8]
        end
      end

      describe 'user assigned to project' do
        before do
          user.add_viewable(p1)
        end
        it 'sees p1' do
          expect(u[user]).to eq p[p1]
        end
      end

      describe 'user assigned to organization' do
        before do
          user.add_viewable(o1)
        end
        it 'sees p1 and p2' do
          expect(u[user]).to eq p[p1, p2]
        end
      end

      describe 'user assigned to data source' do
        before do
          user.add_viewable(ds1)
        end
        it 'sees p1 - p4' do
          expect(u[user]).to eq p[p1, p2, p3, p4]
        end
      end

      describe 'user assigned to coc foo' do
        before do
          user.coc_codes = ['foo']
          user.save
        end
        after do
          user.coc_codes = []
          user.save
        end
        it 'sees p1, p2, p4, p5' do
          expect(u[user]).to eq p[p1, p2, p4, p5]
        end
      end

      describe 'user assigned to coc bar' do
        before do
          user.coc_codes = ['bar']
          user.save
        end
        after do
          user.coc_codes = []
          user.save
        end
        it 'sees p7 and p8' do
          expect(u[user]).to eq p[p7, p8]
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

      describe 'user without permission to view confidential enrollment details' do
        describe 'assigned to confidential project' do
          before do
            user.add_viewable(p1)
          end
          it 'sees p1 confidentialized' do
            expect(u[user]).to eq p[p1]
            expect(p1.name(user).downcase).to include 'confidential'
          end
        end

        describe 'assigned to confidential organization' do
          before do
            user.add_viewable(o2)
          end
          it 'sees p3 and p4 confidentialized' do
            expect(u[user]).to eq p[p3, p4]
            expect(p3.name(user).downcase).to include 'confidential'
            expect(p4.name(user).downcase).to include 'confidential'
          end
        end

        describe 'assigned to coc foo' do
          before do
            user.coc_codes = ['foo']
            user.save
          end
          after do
            user.coc_codes = []
            user.save
          end
          it 'sees p1 and p4 confidentialized' do
            expect(u[user]).to include(p1.id, p4.id)
            expect(p1.name(user).downcase).to include 'confidential'
            expect(p4.name(user).downcase).to include 'confidential'
          end
        end
      end

      describe 'user with permission to view confidential enrollment details' do
        before do
          user.roles << can_view_confidential_projects
        end
        after do
          user.roles = []
        end

        describe 'assigned to confidential project' do
          before do
            user.add_viewable(p1)
          end
          it 'sees p1 project name' do
            expect(u[user]).to eq p[p1]
            expect(p1.name(user).downcase).not_to include 'confidential'
          end
        end

        describe 'assigned to confidential organization' do
          before do
            user.add_viewable(o2)
          end
          it 'sees p3 and p4 project names' do
            expect(u[user]).to eq p[p3, p4]
            expect(p3.name(user).downcase).not_to include 'confidential'
            expect(p4.name(user).downcase).not_to include 'confidential'
          end
        end

        describe 'assigned to coc foo' do
          before do
            user.coc_codes = ['foo']
            user.save
          end
          after do
            user.coc_codes = []
            user.save
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
