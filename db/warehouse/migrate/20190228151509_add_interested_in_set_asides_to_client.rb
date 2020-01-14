class AddInterestedInSetAsidesToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :interested_in_set_asides, :boolean, default: false
  end
end
