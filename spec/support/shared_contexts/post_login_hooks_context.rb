# frozen_string_literal: true

RSpec.shared_context 'with post-authentication hooks' do
  let(:post_auth_user) { user }

  context 'when the user has a password reset token' do
    before do
      post_auth_user.update!(
        reset_password_token: 'some-token',
        reset_password_sent_at: 1.hour.ago,
      )
    end

    context 'with a successful login' do
      it 'clears the reset password token' do
        expect { do_login }.
          to change { post_auth_user.reload.reset_password_token }.to(nil).
          and change { post_auth_user.reload.reset_password_sent_at }.to(nil)
      end
    end

    context 'with a failed login' do
      it 'does not clear the reset password token' do
        expect { do_failed_login }.
          to not_change { post_auth_user.reload.reset_password_token }.
          and(not_change { post_auth_user.reload.reset_password_sent_at })
      end
    end
  end
end
