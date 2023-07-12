class AddHmisUniqueSessionIdToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :hmis_unique_session_id, :string
  end
end
