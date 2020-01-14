class DateOfServiceShouldBeTime < ActiveRecord::Migration[4.2]
  def change
    remove_column :visits, :date_of_service, :date
    add_column :visits, :date_of_service, :datetime
  end
end
