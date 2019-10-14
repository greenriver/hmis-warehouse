class New2020TablesGetPendingDeletedGeographyMovesIntoProjectCoC < ActiveRecord::Migration
  def change

    add_column :ProjectCoC, :geography_type_override, :integer, limit: 4
    add_column :ProjectCoC, :geocode_override, :string, limit: 6

    add_column :CurrentLivingSituation, :pending_date_deleted, :datetime, default: nil
    add_column :Assessment, :pending_date_deleted, :datetime, default: nil
    add_column :AssessmentQuestions, :pending_date_deleted, :datetime, default: nil
    add_column :AssessmentResults, :pending_date_deleted, :datetime, default: nil
    add_column :Event, :pending_date_deleted, :datetime, default: nil
    add_column :User, :pending_date_deleted, :datetime, default: nil

    add_column :CurrentLivingSituation, :source_hash, :varchar
    add_column :Assessment, :source_hash, :varchar
    add_column :AssessmentQuestions, :source_hash, :varchar
    add_column :AssessmentResults, :source_hash, :varchar
    add_column :Event, :source_hash, :varchar
    add_column :User, :source_hash, :varchar

    add_index :CurrentLivingSituation, :pending_date_deleted
    add_index :Assessment, :pending_date_deleted
    add_index :AssessmentQuestions, :pending_date_deleted
    add_index :AssessmentResults, :pending_date_deleted
    add_index :Event, :pending_date_deleted
    add_index :User, :pending_date_deleted
  end
end
