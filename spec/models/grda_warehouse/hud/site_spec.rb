require 'rails_helper'

model = GrdaWarehouse::Hud::Geography
RSpec.describe model, type: :model do

  let!(:admin_role) { create :admin_role }

  let!(:user) { create :user }

  let!(:ds1) { create :source_data_source, id: 1 }
  let!(:ds2) { create :source_data_source, id: 2 }

  let!(:pc1) { create :hud_project_coc, CoCCode: 'foo', data_source_id: ds1.id }
  let!(:pc2) { create :hud_project_coc, CoCCode: 'bar', data_source_id: ds2.id }

  let!(:s1) { create :hud_geography, data_source_id: pc1.data_source_id, ProjectID: pc1.ProjectID, CoCCode: pc1.CoCCode }
  let!(:s2) { create :hud_geography, data_source_id: pc2.data_source_id, ProjectID: pc2.ProjectID, CoCCode: pc2.CoCCode }

  user_ids = -> (user) { model.viewable_by(user).pluck(:id).sort }
  ids      = -> (*sites) { sites.map(&:id).sort }

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
        end
        after do
          user.roles = []
        end
        it 'sees both' do
          expect(user_ids[user]).to eq ids[ s1, s2 ]
        end
      end

      describe 'user assigned to coc foo' do
        before do
          user.coc_codes << 'foo'
          user.save
        end
        after do
          user.coc_codes = []
          user.save
        end
        it 'sees s1' do
          expect(user_ids[user]).to eq ids[s1]
        end
      end

    end
  end


end
