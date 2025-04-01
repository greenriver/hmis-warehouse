###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

model = GrdaWarehouse::Hud::ProjectCoc
RSpec.describe model, type: :model do
  let!(:admin_role) { create :admin_role }

  let!(:user) { create :acl_user }

  let!(:ds1) { create :source_data_source, id: 1 }

  let!(:p1) { create :hud_project, data_source_id: ds1.id }
  let!(:p2) { create :hud_project, data_source_id: ds1.id }

  let!(:pc1) { create :hud_project_coc, CoCCode: 'XX-500', data_source_id: ds1.id, project: p1 }
  let!(:pc2) { create :hud_project_coc, CoCCode: 'XX-501', data_source_id: ds1.id, project: p2 }

  let!(:can_view_projects) { create :role, can_view_projects: true }
  let!(:coc_code_collection) { create :collection }

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
          Collection.maintain_system_groups
          setup_access_control(user, admin_role, Collection.system_collection(:data_sources))
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees both' do
          expect(user_ids[user]).to eq ids[pc1, pc2]
        end
      end

      describe 'user assigned to coc XX-500' do
        before do
          coc_code_collection.set_viewables({ coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: ['XX-500']).pluck(:id) })
          setup_access_control(user, can_view_projects, coc_code_collection)
        end
        it 'sees pc1' do
          expect(user_ids[user]).to eq ids[pc1]
        end
      end
    end
  end
end
