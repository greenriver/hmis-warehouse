###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared context for testing timing attack mitigation in session controllers
#
# Required let variables:
#   - user: The user to test with
#   - controller_class: The controller class being tested (e.g., Hmis::SessionsController)
#
# Required methods:
#   - do_login: Method that performs a successful login
#   - do_failed_login: Method that performs a failed login attempt
#   - do_nonexistent_user_login: Method that attempts login with non-existent user
#   - assert_success: Method that verifies successful login response
#   - assert_failure: Method that verifies failed login response
RSpec.shared_context 'with timing attack mitigation' do
  describe 'Timing attack mitigation' do
    it 'enforces minimum login time for successful login' do
      start_time = Time.current
      do_login
      elapsed = Time.current - start_time

      assert_success
      expect(elapsed).to be >= controller_class::MIN_REQ_LOGIN_TIME
    end

    it 'enforces minimum login time for failed login' do
      start_time = Time.current
      do_failed_login
      elapsed = Time.current - start_time

      assert_failure
      expect(elapsed).to be >= controller_class::MIN_REQ_LOGIN_TIME
    end

    it 'enforces minimum login time for locked account' do
      user.lock_access!
      start_time = Time.current
      do_login
      elapsed = Time.current - start_time

      assert_failure
      expect(elapsed).to be >= controller_class::MIN_REQ_LOGIN_TIME
    end

    it 'enforces minimum login time for non-existent user' do
      start_time = Time.current
      do_nonexistent_user_login
      elapsed = Time.current - start_time

      assert_failure
      expect(elapsed).to be >= controller_class::MIN_REQ_LOGIN_TIME
    end

    it 'successful and failed logins take similar time' do
      # Measure failed login time
      failed_start = Time.current
      do_failed_login
      failed_elapsed = Time.current - failed_start
      assert_failure

      # Reset user state
      user.reload.update(failed_attempts: 0)

      # Measure successful login time
      success_start = Time.current
      do_login
      success_elapsed = Time.current - success_start
      assert_success

      # Both should take at least MIN_REQ_LOGIN_TIME
      expect(failed_elapsed).to be >= controller_class::MIN_REQ_LOGIN_TIME
      expect(success_elapsed).to be >= controller_class::MIN_REQ_LOGIN_TIME

      # Time difference should be within reasonable bounds (accounting for random delay)
      # Both have random 0.5-1s added, so max difference should be ~1.5s
      time_difference = (failed_elapsed - success_elapsed).abs
      expect(time_difference).to be < 2.0
    end
  end
end
