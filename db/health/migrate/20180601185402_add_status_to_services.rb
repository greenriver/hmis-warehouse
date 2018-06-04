class AddStatusToServices < ActiveRecord::Migration
  def change
    add_column :services, :status, :string
  end
end
