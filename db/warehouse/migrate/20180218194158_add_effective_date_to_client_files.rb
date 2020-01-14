class AddEffectiveDateToClientFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :effective_date, :date
  end
end
