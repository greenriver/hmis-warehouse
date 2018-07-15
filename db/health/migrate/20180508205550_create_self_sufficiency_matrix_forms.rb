class CreateSelfSufficiencyMatrixForms < ActiveRecord::Migration
  def change
    create_table :self_sufficiency_matrix_forms do |t|
      t.belongs_to :patient
      t.belongs_to :user
      t.string  :point_completed
      t.integer :housing_score
      t.text    :housing_notes

      t.integer :income_score
      t.text    :income_notes
      
      t.integer :benefits_score
      t.text    :benefits_notes
      
      t.integer :disabilities_score
      t.text    :disabilities_notes
      
      t.integer :food_score
      t.text    :food_notes
      
      t.integer :employment_score
      t.text    :employment_notes
      
      t.integer :education_score
      t.text    :education_notes
      
      t.integer :mobility_score
      t.text    :mobility_notes
      
      t.integer :life_score
      t.text    :life_notes
      
      t.integer :healthcare_score
      t.text    :healthcare_notes
      
      t.integer :physical_health_score
      t.text    :physical_health_notes
      
      t.integer :mental_health_score
      t.text    :mental_health_notes
      
      t.integer :substance_abuse_score
      t.text    :substance_abuse_notes
      
      t.integer :criminal_score
      t.text    :criminal_notes
      
      t.integer :legal_score
      t.text    :legal_notes
      
      t.integer :safety_score
      t.text    :safety_notes
      
      t.integer :risk_score
      t.text    :risk_notes
      
      t.integer :family_score
      t.text    :family_notes
      
      t.integer :community_score
      t.text    :community_notes
      
      t.integer :time_score
      t.text    :time_notes

      t.datetime :completed_at
    end
  end
end
