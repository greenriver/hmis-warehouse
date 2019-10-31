require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  include_context 'visibility test context'

  context 'when config b is in affect' do
    let!(:config) { create :config_b }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(4)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_client_window
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting can search window' do
      before do
        user.roles << can_search_window
      end
      it 'user can see only window clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).pluck(:id)).to include(window_source_client.id)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_see_clients_in_window_for_assigned_data_sources
      end
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source' do
          expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(1)
          expect(GrdaWarehouse::Hud::Client.viewable_by(user).pluck(:id)).to include(non_window_source_client.id)
        end
        describe 'and the user can search the window' do
          before do
            user.roles << can_search_window
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(2)
          end
        end
      end
    end
  end

  context 'when config b is in affect' do
    let!(:config) { create :config_s }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(4)
      end
    end
  end

  context 'when config b is in affect' do
    let!(:config) { create :config_3c }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(4)
      end
    end
  end

  context 'when config b is in affect' do
    let!(:config) { create :config_tc }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(4)
      end
    end
  end

  context 'when config b is in affect' do
    let!(:config) { create :config_ma }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
      end
      it 'user can see all clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(4)
      end
    end
  end
end
