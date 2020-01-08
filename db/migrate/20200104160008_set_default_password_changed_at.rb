class SetDefaultPasswordChangedAt < ActiveRecord::Migration[5.2]
  def up
    User.where(password_changed_at: nil).update_all(password_changed_at: Time.current)
  end
end
