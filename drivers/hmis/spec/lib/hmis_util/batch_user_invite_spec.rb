###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::BatchUserInvite do
  describe '.send_pending_invitations', :devise_only do
    let(:system_user) { User.system_user }

    def invite_without_email(email)
      User.invite!({ email: email, first_name: 'Pending', last_name: 'User', agency_id: 1 }, system_user) do |u|
        u.skip_invitation = true
      end
    end

    def grant_hmis_access(*users)
      create(:hmis_access_control, with_users: users)
    end

    def run(dry_run:)
      described_class.send_pending_invitations(dry_run: dry_run)
    end

    before do
      ActionMailer::Base.deliveries.clear
      allow($stdout).to receive(:puts)
    end

    context 'when choosing which users to invite' do
      let!(:pending_hmis_user) { invite_without_email('pending-hmis@example.com') }
      let!(:pending_warehouse_only_user) { invite_without_email('pending-warehouse@example.com') }
      let!(:accepted_hmis_user) do
        invite_without_email('accepted@example.com').tap { |u| u.update_columns(invitation_accepted_at: 1.day.ago) }
      end
      let!(:already_sent_hmis_user) do
        User.invite!({ email: 'sent@example.com', first_name: 'Sent', last_name: 'User', agency_id: 1 }, system_user)
      end
      let!(:never_invited_hmis_user) { create(:user, email: 'direct@example.com') }

      before do
        grant_hmis_access(pending_hmis_user, accepted_hmis_user, already_sent_hmis_user, never_invited_hmis_user, system_user)
        ActionMailer::Base.deliveries.clear
      end

      it 'invites only HMIS users whose invitation has a token but was never sent or accepted' do
        result = run(dry_run: false)

        expect(result).to contain_exactly(pending_hmis_user)
        expect(ActionMailer::Base.deliveries.flat_map(&:to)).to contain_exactly('pending-hmis@example.com')
      end

      it 'leaves the excluded users untouched' do
        run(dry_run: false)

        expect(pending_warehouse_only_user.reload.invitation_sent_at).to be_nil
        expect(never_invited_hmis_user.reload.invitation_token).to be_nil
        expect(accepted_hmis_user.reload.invitation_accepted_at).to be_present
      end

      it 'never invites the system user, even when it holds an HMIS grant' do
        run(dry_run: false)

        expect(system_user.reload.invitation_sent_at).to be_nil
      end
    end

    context 'when sending' do
      let!(:user) { invite_without_email('pending@example.com') }
      let(:stale_created_at) { 3.weeks.ago.change(usec: 0) }

      before do
        grant_hmis_access(user)
        user.update_columns(invitation_created_at: stale_created_at)
      end

      it 'records the send and refreshes the invitation creation time so the link is not already expired' do
        run(dry_run: false)
        user.reload

        expect(user.invitation_sent_at).to be_within(1.minute).of(Time.current)
        expect(user.invitation_created_at).to be > stale_created_at
        expect(user.invitation_due_at).to be > Time.current
      end

      it 'delivers one activation email to the user' do
        run(dry_run: false)

        expect(ActionMailer::Base.deliveries.size).to eq(1)
        mail = ActionMailer::Base.deliveries.first
        expect(mail.to).to eq(['pending@example.com'])
        expect(mail.subject).to include('Account Activation Instructions')
      end

      it 'does not invite the same user on a second run' do
        run(dry_run: false)
        second = run(dry_run: false)

        expect(second).to be_empty
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end
    end

    context 'when dry_run is true' do
      let!(:user) { invite_without_email('pending@example.com') }

      before { grant_hmis_access(user) }

      it 'lists the pending users without sending anything' do
        result = run(dry_run: true)

        expect(result).to contain_exactly(user)
        expect(ActionMailer::Base.deliveries).to be_empty
        expect(user.reload.invitation_sent_at).to be_nil
      end

      it 'defaults to dry_run' do
        described_class.send_pending_invitations

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context 'when a pending user fails validation' do
      let!(:invalid_user) do
        invite_without_email('invalid@example.com').tap { |u| u.update_columns(last_name: '') }
      end
      let!(:valid_user) { invite_without_email('valid@example.com') }

      before { grant_hmis_access(invalid_user, valid_user) }

      it 'reports the failure and still invites the other users' do
        expect { run(dry_run: false) }.not_to raise_error

        expect($stdout).to have_received(:puts).with(a_string_matching(/Failed to invite invalid@example.com/))
        expect(ActionMailer::Base.deliveries.flat_map(&:to)).to contain_exactly('valid@example.com')
        expect(invalid_user.reload.invitation_sent_at).to be_nil
      end
    end
  end
end
