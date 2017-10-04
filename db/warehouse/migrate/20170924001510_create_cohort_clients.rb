class CreateCohortClients < ActiveRecord::Migration
  def change
    create_table :cohort_clients do |t|
      t.references :cohort, index: true, null: false
      t.references :client, index: true, null: false
      t.timestamps null: false
      t.datetime :deleted_at, index: true
      t.string :agency
      t.string :case_manager
      t.string :housing_manager
      t.string :housing_search_agency
      t.string :housing_opportunity
      t.string :legal_barriers
      t.string :criminal_record_status
      t.string :document_ready
      t.string :sif_eligible
      t.string :sensory_impaired
      t.date :housed_date
      t.string :destination
      t.string :sub_population
      t.integer :rank
      t.string :st_francis_house
      t.date :last_group_review_date
      t.date :pre_contemplative_last_date_approached
      t.string :housing_track
      t.date :va_eligible
      t.string :vash_eligible
      t.string :chapter_115
    end

    create_table :cohort_client_notes do |t|
      t.references :cohort_client, index: true, null: false
      t.text :note
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end
