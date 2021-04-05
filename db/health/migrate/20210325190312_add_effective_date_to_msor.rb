class AddEffectiveDateToMsor < ActiveRecord::Migration[5.2]
  def change
    add_column :member_status_reports, :effective_date, :date
  end
end
