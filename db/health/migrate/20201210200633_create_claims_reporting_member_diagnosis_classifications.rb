class CreateClaimsReportingMemberDiagnosisClassifications < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_member_diagnosis_classifications do |t|
      t.string :member_id, null: false, index: {name: 'unk_crmd'}
      t.boolean :currently_assigned
      t.boolean :currently_engaged
      t.boolean :ast # asthma
      t.boolean :cpd # copd
      t.boolean :cir # cardiac disease
      t.boolean :dia # diabetes
      t.boolean :spn # degenerative spinal disease/chronic pain
      t.boolean :gbt # gi and bilary tract disease
      t.boolean :obs # obesity
      t.boolean :hyp # hypertension
      t.boolean :hep # hepatitis
      t.boolean :sch # schizophrenia
      t.boolean :pbd # psychoses/bipolar disorders
      t.boolean :das # depression/anxiety/stress reactions
      t.boolean :pid # personality/impulse disorder
      t.boolean :sia # suicidal ideation/attempt
      t.boolean :sud # Substance Abuse Disorder
      t.boolean :coi
      t.boolean :high_er
      t.boolean :psychoses
      t.boolean :other_ip_psych
      t.integer :engaged_member_days
      t.integer :antipsy_day
      t.integer :antipsy_denom
      t.integer :antidep_day
      t.integer :antidep_denom
      t.integer :moodstab_day
      t.integer :moodstab_denom
      t.timestamps
    end
  end
end
