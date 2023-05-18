require 'rails_helper'

model = GrdaWarehouse::Hud::ProjectCoc
RSpec.describe model, type: :model do
  let!(:admin_role) { create :admin_role }

  let!(:user) { create :user }

  let!(:ds1) { create :source_data_source, id: 1 }

  let!(:p1) { create :hud_project, data_source_id: ds1.id }
  let!(:p2) { create :hud_project, data_source_id: ds1.id }

  let!(:pc1) { create :hud_project_coc, CoCCode: 'foo', data_source_id: ds1.id, project: p1 }
  let!(:pc2) { create :hud_project_coc, CoCCode: 'bar', data_source_id: ds1.id, project: p2 }

  let!(:can_view_projects) { create :role, can_view_projects: true }
  let!(:coc_code_viewable) { create :access_group }

  # NOTE ProjectCoC defaults to reporting access
  user_ids = ->(user) { model.viewable_by(user, permission: :can_view_projects).pluck(:id).sort }
  ids      = ->(*pcs) { pcs.map(&:id).sort }

  describe 'scopes' do
    describe 'viewability' do
      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.viewable_by(user, permission: :can_view_projects).exists?).to be false
        end
      end

      describe 'admin user' do
        before do
          AccessGroup.maintain_system_groups
          setup_access_control(user, admin_role, AccessGroup.where(name: 'All Data Sources').first)
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees both' do
          expect(user_ids[user]).to eq ids[pc1, pc2]
        end
      end

      describe 'user assigned to coc foo' do
        before do
          coc_code_viewable.update(coc_codes: ['foo'])
          setup_access_control(user, can_view_projects, coc_code_viewable)
        end
        it 'sees pc1' do
          expect(user_ids[user]).to eq ids[pc1]
        end
      end
    end
  end
end
