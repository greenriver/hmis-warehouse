class SetProviderSetOnUser < ActiveRecord::Migration[5.2]
  def up
    # stop email from going out on every login
    User.where.not(provider: nil).update_all(provder_set_at: Time.current)
  end
end
