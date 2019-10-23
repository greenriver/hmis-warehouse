class AddVacancyIdToCasReporting < ActiveRecord::Migration
  def change
    add_column :cas_reports, :vacancy_id, :integer
  end
end
