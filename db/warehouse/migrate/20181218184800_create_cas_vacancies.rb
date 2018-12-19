class CreateCasVacancies < ActiveRecord::Migration
  def change
    create_table :cas_vacancies do |t|
      t.integer :program_id, null: false, index: true
      t.integer :sub_program_id, null: false, index: true
      t.string :program_name
      t.string :sub_program_name
      t.string :program_type
      t.string :route_name, null: false
      t.datetime :vacancy_created_at, null: false
      t.datetime :vacancy_made_available_at
      t.datetime :first_matched_at
    end
  end
end
