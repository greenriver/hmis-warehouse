class AddSoEnrollmentFlag < ActiveRecord::Migration
  def change
    add_column :configs, :so_day_as_month, :boolean, default: true
  end
end
