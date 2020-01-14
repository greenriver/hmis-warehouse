class AddVacancyIdToCasReporting < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :vacancy_id, :integer
  end
end
