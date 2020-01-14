class AddStatusToServices < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :status, :string
  end
end
