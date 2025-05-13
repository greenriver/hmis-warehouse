class AddFy2026Columns < ActiveRecord::Migration[7.1]
  def change
    add_column :Client, :Sex, :integer
    add_column :Enrollment, :MentalHealthConsultation, :integer
    add_column :Services, :InformationDate, :date
  end
end
