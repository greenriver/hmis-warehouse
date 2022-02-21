class DeActivateUsers < ActiveRecord::Migration[6.1]
  def up
    # de-activate any user who hasn't signed in since the end of 2020
    User.active.where(current_sign_in_at: '2010-01-01'.to_time..'2020-12-30'.to_time).update_all(
      expired_at: DateTime.current,
      active: false,
    )
    # also catch those who never signed in, and their account hasn't been touched since the end of 2020
    User.active.where(current_sign_in_at: nil, updated_at: '2010-01-01'.to_time..'2020-12-30'.to_time).update_all(
      expired_at: DateTime.current,
      active: false,
    )
  end
end
