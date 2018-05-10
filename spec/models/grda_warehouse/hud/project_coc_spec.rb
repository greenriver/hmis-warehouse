require 'rails_helper'

model = GrdaWarehouse::Hud::ProjectCoc
RSpec.describe model, type: :model do  

  let! :admin_role { create :admin_role }

  let! :user { create :user }

  let! :pc1 { create :hud_project_coc, CoCCode: 'foo' }
  let! :pc2 { create :hud_project_coc, CoCCode: 'bar' }

  user_ids = -> (user) { model.viewable_by(user).pluck(:id).sort }
  ids      = -> (*pcs) { pcs.map(&:id).sort }

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
          expect(user_ids[user]).to eq ids[ pc1, pc2 ]
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
        it 'sees pc1' do
          expect(user_ids[user]).to eq ids[pc1]
        end
      end
    end
  end


end
