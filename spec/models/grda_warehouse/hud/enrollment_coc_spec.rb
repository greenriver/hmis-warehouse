require 'rails_helper'

model = GrdaWarehouse::Hud::EnrollmentCoc
RSpec.describe model, type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
  end
  let!(:admin_role) { create :admin_role }

  let!(:user) { create :acl_user }

  let!(:ec1) { create :hud_enrollment_coc, CoCCode: 'foo' }
  let!(:ec2) { create :hud_enrollment_coc, CoCCode: 'bar' }
  let!(:coc_code_collection) { create :collection }

  user_ids = ->(user) { model.viewable_by(user).pluck(:id).sort }
  ids      = ->(*ecs) { ecs.map(&:id).sort }

  describe 'scopes' do
    describe 'viewability' do
      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.viewable_by(user).pluck(:id)).to eq([])
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
          expect(user_ids[user]).to eq ids[ec1, ec2]
        end
      end

      describe 'user assigned to coc foo' do
        before do
          coc_code_collection.update(coc_codes: ['foo'])
          setup_access_control(user, admin_role, coc_code_collection)
        end
        it 'sees ec1' do
          expect(user_ids[user]).to eq ids[ec1]
        end
      end
    end
  end
end
