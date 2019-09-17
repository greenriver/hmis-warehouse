class AddSexualOrientationToHmisClient < ActiveRecord::Migration
  def change
    add_column :hmis_clients, :sexual_orientation, :string
  end
end
