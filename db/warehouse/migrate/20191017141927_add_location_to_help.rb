class AddLocationToHelp < ActiveRecord::Migration[4.2]
  def change
    add_column :helps, :location, :string, default: :internal, null: false
  end
end
