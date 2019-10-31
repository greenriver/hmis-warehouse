class AddSexualOrientationToHmisClient < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_clients, :sexual_orientation, :string
  end
end
