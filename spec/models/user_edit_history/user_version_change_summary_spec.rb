require 'rails_helper'

RSpec.describe UserEditHistory::UserVersionChangeSummary do
  let(:summary) { described_class.new }
  let(:user) { create(:user) }

  shared_examples 'change pattern' do |event:, changes:, expected_summary:, whodunnit: 'test'|
    let(:version) do
      create(
        :gr_paper_trail_version,
        item: user,
        event: event,
        whodunnit: whodunnit,
        object_changes: changes.merge('updated_at' => [1.day.ago, Time.current]).to_yaml,
      )
    end

    it "summarizes as '#{expected_summary}'" do
      expect(summary.perform(version, version.changeset)).to eq(Array.wrap(expected_summary))
    end
  end

  describe '#perform' do
    context 'common events' do
      {
        'account creation' => {
          event: 'create',
          changes: {},
          expected_summary: 'Account created',
        },
        'account deletion' => {
          event: 'destroy',
          changes: {},
          expected_summary: 'Account deleted',
        },
        'account deactivation' => {
          event: 'update',
          changes: { 'active' => [true, false] },
          expected_summary: 'Account deactivated',
        },
        'account activation' => {
          event: 'update',
          changes: { 'active' => [false, true] },
          expected_summary: 'Account activated',
        },
        'invitation sent' => {
          event: 'update',
          changes: {
            'invitation_created_at' => [nil, Time.current],
            'invitation_sent_at' => [nil, Time.current],
            'invitation_token' => [nil, 'token'],
          },
          expected_summary: 'Invitation Sent',
        },
        'invitation accepted' => {
          event: 'update',
          changes: {
            'confirmed_at' => [nil, Time.current],
            'encrypted_password' => ['old', 'new'],
            'invitation_accepted_at' => [nil, Time.current],
            'invitation_token' => ['token', nil],
            'password_changed_at' => [nil, Time.current],
          },
          whodunnit: nil,
          expected_summary: 'Invitation accepted',
        },
        'password reset email' => {
          event: 'update',
          changes: {
            'reset_password_sent_at' => [nil, Time.current],
            'reset_password_token' => [nil, 'token'],
          },
          expected_summary: 'Password reset email sent',
        },
        'password reset' => {
          event: 'update',
          changes: {
            'encrypted_password' => ['old', 'new'],
            'password_changed_at' => [1.day.ago, Time.current],
          },
          expected_summary: 'Password reset',
        },
        'password reset from form' => {
          event: 'update',
          changes: {
            'encrypted_password' => ['old', 'new'],
            'password_changed_at' => [1.day.ago, Time.current],
            'reset_password_sent_at' => [nil, Time.current],
            'reset_password_token' => [nil, nil],
          },
          whodunnit: nil,
          expected_summary: 'Password reset from forgot-password form',
        },
      }.each do |name, config|
        context name do
          include_examples 'change pattern', **config
        end
      end
    end

    context 'when changes are not summarizable' do
      let(:version) do
        create(
          :gr_paper_trail_version,
          item: user,
          event: 'update',
          object_changes: {
            'email' => ['old@example.com', 'new@example.com'],
            'updated_at' => [1.day.ago, Time.current],
          }.to_yaml,
        )
      end

      it 'provides detailed changes' do
        expect(summary.perform(version, version.changeset)).
          to eq(['Changed Email: from "old@example.com" to "new@example.com".'])
      end
    end

    context 'with invalid version' do
      it 'raises ArgumentError' do
        expect { summary.perform(Object.new, {}) }.to raise_error(ArgumentError)
      end
    end
  end
end
