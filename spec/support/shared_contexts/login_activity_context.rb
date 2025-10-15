# frozen_string_literal: true

RSpec.shared_context 'with login activity tracking' do
  it 'creates a successful login activity' do
    expect do
      do_login
    end.to change(LoginActivity, :count).by(1)
    activity = LoginActivity.where(user: activity_user, scope: scope, success: true).sole
    expect(activity).to have_attributes(user: activity_user, success: true, scope: scope)
  end

  it 'creates a failed login activity' do
    expect do
      do_failed_login
    end.to change(LoginActivity, :count).by(1)
    activity = LoginActivity.where(user: activity_user, scope: scope, success: false).sole
    expect(activity).to have_attributes(user: activity_user, success: false, scope: scope)
  end
end
