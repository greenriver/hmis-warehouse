class AddInformationDateToCustomCaseNotes < ActiveRecord::Migration[6.1]
  def change
    add_column :CustomCaseNote, :information_date, :date, null: true
  end
end
