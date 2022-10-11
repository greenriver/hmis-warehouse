class CreateCePerformanceGoals < ActiveRecord::Migration[6.1]
  def change
    create_table :ce_performance_goals do |t|
      t.string :coc_code, null: false
      {
        screening: 100,
        diversion: 5,
        time_in_ce: 30,
        time_to_referral: 5,
        time_to_housing: 5,
        time_on_list: 30,
      }.each do |column, default|
        t.integer column, default: default, null: false
      end
      t.timestamps null: false
      t.datetime :deleted_at
    end
  end
end
