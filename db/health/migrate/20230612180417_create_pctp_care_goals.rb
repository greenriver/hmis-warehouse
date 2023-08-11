class CreatePctpCareGoals < ActiveRecord::Migration[6.1]
  def change
    create_table :pctp_care_goals do |t|
      t.references :careplan

      t.string :domain
      t.string :goal
      t.string :status

      t.date :estimated_completion_date
      t.date :start_date
      t.date :end_date

      t.string :barriers
      t.string :followup
      t.string :comments
      t.string :source
      t.string :priority

      t.string :plan
      t.string :responsible_party
      t.string :times
      t.string :interval

      t.timestamps
    end
  end
end
