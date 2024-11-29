require 'rails_helper'

RSpec.describe UserEditHistory::DisplayItem do
  let(:user) { create(:user, first_name: 'Test', last_name: 'User') }
  let(:true_user) { create(:user, first_name: 'True', last_name: 'User') }
  let(:version) do
    create(
      :gr_paper_trail_version,
      item: user,
      whodunnit: "#{true_user.id} as #{user.id}", # impersonator
    )
  end

  let(:users_by_id) { { user.id => user, true_user.id => true_user } }

  it 'handles impersonation correctly' do
    item = described_class.new(version, users_by_id)
    expect(item.username).to eq('True User impersonating Test User')
  end

  it 'handles missing users gracefully' do
    item = described_class.new(version, {})
    expect(item.username).to eq(version.whodunnit)
  end

  context 'when model no longer exists' do
    before do
      allow(version).to receive(:item_type).and_return('NonExistentModel')
    end

    it 'sets error flag' do
      item = described_class.new(version, users_by_id)
      expect(item.error).to be true
    end
  end
end
