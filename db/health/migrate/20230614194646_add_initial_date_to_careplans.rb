class AddInitialDateToCareplans < ActiveRecord::Migration[6.1]
  def change
    add_column :pctp_careplans, :initial_date, :date
  end
end
