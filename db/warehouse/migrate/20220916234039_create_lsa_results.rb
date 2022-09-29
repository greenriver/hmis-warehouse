class CreateLsaResults < ActiveRecord::Migration[6.1]
  def change
    create_table :hud_lsa_summary_results do |t|
      t.references :hud_report_instance
      t.jsonb :summary
      t.timestamps
    end
  end
end
