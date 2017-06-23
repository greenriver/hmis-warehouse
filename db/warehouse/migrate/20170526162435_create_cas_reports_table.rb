class CreateCasReportsTable < ActiveRecord::Migration
  def change
    create_table :cas_reports do |t|
      t.integer  :client_id, null: false
      t.integer  :match_id, null: false
      t.integer  :decision_id, null: false
      t.integer  :decision_order, null: false
      t.string   :match_step, null: false
      t.string   :decision_status, null: false
      t.boolean  :current_step, null: false, default: false
      t.boolean  :active_match, null: false, default: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer  :elapsed_days, null: false, default: 0
      t.datetime :client_last_seen_date
      t.datetime :criminal_hearing_date
      t.string   :decline_reason
      t.string   :not_working_with_client_reason
      t.string   :administrative_cancel_reason
      t.boolean  :client_spoken_with_services_agency
      t.boolean  :cori_release_form_submitted

      t.index [:client_id, :match_id, :decision_id], unique: true
    end
  end
end
