
require 'rails_helper'

RSpec.describe UserEditHistory::Versions do
  let(:user) { create(:user) }
  let(:versions) { described_class.new(user) }

  describe '#version_scope' do
    before do
      # Create login-related version
      create(:gr_paper_trail_version,
             item: user,
             object_changes: {
               'sign_in_count' => [1, 2],
               'current_sign_in_at' => [1.day.ago, Time.current],
               'updated_at' => [1.day.ago, Time.current]
             }.to_yaml)

      # Create non-login version
      create(:gr_paper_trail_version,
             item: user,
             object_changes: {
               'email' => ['old@example.com', 'new@example.com'],
               'updated_at' => [1.day.ago, Time.current]
             }.to_yaml)
    end

    it 'excludes login-related versions' do
      expect(versions.version_scope.count).to eq(1)
      expect(versions.version_scope.first.changeset.keys).to include('email')
    end
  end

  describe '#wrap_display_versions' do
    let!(:editor) { create(:user) }
    let!(:version) do
      create(:gr_paper_trail_version, item: user, whodunnit: editor.id.to_s)
    end

    it 'loads users' do
      display_items = versions.wrap_display_versions([version])
      expect(display_items.first.username).to eq(editor.name)
    end
  end
end
