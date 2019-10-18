class AddLocationToHelp < ActiveRecord::Migration
  def change
    add_column :helps, :location, :string, default: :internal, null: false
  end
end
