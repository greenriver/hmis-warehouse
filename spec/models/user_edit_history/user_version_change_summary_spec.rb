require 'rails_helper'

RSpec.describe UserEditHistory::UserVersionChangeSummary do
  let(:summary) { described_class.new }

  let(:user) { create(:user) }

  context 'when account is activated' do
    let(:version) do
      create(:gr_paper_trail_version,
             item: user,
             event: 'update',
             object_changes: {
               'active' => [false, true],
               'updated_at' => [1.day.ago, Time.current],
             }.to_yaml)
    end

    it 'summarizes activation' do
      expect(summary.perform(version, version.changeset)).to eq(['Account activated'])
    end
  end

  context 'when password is reset' do
    let(:version) do
      create(:gr_paper_trail_version,
             item: user,
             event: 'update',
             whodunnit: 'test',
             object_changes: {
               'encrypted_password' => ['old', 'new'],
               'password_changed_at' => [1.day.ago, Time.current],
               'updated_at' => [1.day.ago, Time.current],
             }.to_yaml)
    end

    it 'summarizes password reset' do
      expect(summary.perform(version, version.changeset)).to eq(['Password reset'])
    end
  end
end
