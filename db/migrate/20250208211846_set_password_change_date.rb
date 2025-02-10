class SetPasswordChangeDate < ActiveRecord::Migration[7.0]
  def up
    # For anyone who hasn't changed their password since we added password_changed_at (password expiration)
    # ensure they aren't forced to change their password on next login since we're making the
    # default that passwords can expire.
    # Using a date 1 year in the past so that _if_ a site is configured to require password changes, it
    # will be triggered.
    User.where(password_changed_at: nil).update_all(password_changed_at: 1.years.ago)
  end
end
