# frozen_string_literal: true

RSpec.shared_context 'with login activity tracking' do
  it 'creates a successful login activity' do
    do_login
    activity = LoginActivity.where(user: activity_user, scope: scope, success: true).order(:created_at).sole
    expect(activity).to be_present
    expect(activity).to have_attributes(user: activity_user, success: true, scope: scope)
  end

  it 'creates a failed login activity' do
    do_failed_login
    activity = LoginActivity.where(user: activity_user, scope: scope, success: false).order(:created_at).sole

    expect(activity).to be_present
    expect(activity).to have_attributes(user: activity_user, success: false, scope: scope)
  end
end
