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
  end

  context 'when config b is in affect' do
    let!(:config) { create :config_s }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
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
  end

  context 'when config b is in affect' do
    let!(:config) { create :config_tc }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
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
  end
end
