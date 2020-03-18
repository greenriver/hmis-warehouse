class AddDvRrhDesiredToClient < ActiveRecord::Migration[5.2]
  def change
    add_column :Client, :dv_rrh_desired, :boolean, default: false
  end
end
