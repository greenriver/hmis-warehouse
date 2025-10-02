# frozen_string_literal: true

RSpec.shared_context 'with post-authentication hooks' do
  context 'when the user has a password reset token' do
    before do
      user.update!(
        reset_password_token: 'some-token',
        reset_password_sent_at: 1.hour.ago,
      )
    end

    it 'clears the reset password token' do
      do_login
      user.reload
      expect(user.reset_password_token).to be_nil
      expect(user.reset_password_sent_at).to be_nil
    end
  end
end
