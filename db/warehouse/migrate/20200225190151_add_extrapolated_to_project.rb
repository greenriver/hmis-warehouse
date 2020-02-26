class AddExtrapolatedToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :Project, :extrapolate_contacts, :boolean, default: false, null: false
  end
end
