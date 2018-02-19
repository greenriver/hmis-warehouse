class AddEffectiveDateToClientFiles < ActiveRecord::Migration
  def change
    add_column :files, :effective_date, :date
  end
end
