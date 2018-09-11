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

  user_ids = -> (user) { model.viewable_by(user).pluck(:id).sort }
  ids      = -> (*sources) { sources.map(&:id).sort }

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
          expect(user_ids[user]).to eq ids[ ds1, ds2 ]
        end
      end

      describe 'user assigned to project' do
        after :each do
          user.entities.destroy_all
        end
        it 'sees ds1' do
          user.entities.create entity: p1
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          user.entities.create entity: p1
          user.entities.create entity: p5
          expect(user_ids[user]).to eq ids[ ds1, ds2 ]
        end
      end

      describe 'user assigned to organization' do
        after :each do
          user.entities.destroy_all
        end
        it 'sees ds1' do
          user.entities.create entity: o1
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          user.entities.create entity: o1
          user.entities.create entity: o3
          expect(user_ids[user]).to eq ids[ ds1, ds2 ]
        end
      end

      describe 'user assigned to data source' do
        after :each do
          user.entities.destroy_all
        end
        it 'sees ds1' do
          user.entities.create entity: ds1
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          user.entities.create entity: ds1
          user.entities.create entity: ds2
          expect(user_ids[user]).to eq ids[ ds1, ds2 ]
        end
      end

    end
  end


end
