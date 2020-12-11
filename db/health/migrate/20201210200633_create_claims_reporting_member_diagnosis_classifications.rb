class CreateClaimsReportingMemberDiagnosisClassifications < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_member_diagnosis_classifications do |t|
      t.string :member_id, null: false, index: {name: 'unk_crmd'}
      t.boolean :currently_assigned
      t.boolean :currently_engaged
      t.boolean :ast, comment: 'asthma'
      t.boolean :cpd, comment: 'copd'
      t.boolean :cir, comment: 'cardiac disease'
      t.boolean :dia, comment: 'diabetes'
      t.boolean :spn, comment: 'degenerative spinal disease/chronic pain'
      t.boolean :gbt, comment: 'gi and biliary tract disease'
      t.boolean :obs, comment: 'obesity'
      t.boolean :hyp, comment: 'hypertension'
      t.boolean :hep, comment: 'hepatitis'
      t.boolean :sch, comment: 'schizophrenia'
      t.boolean :pbd, comment: 'psychoses/bipolar disorders'
      t.boolean :das, comment: 'depression/anxiety/stress reactions'
      t.boolean :pid, comment: 'personality/impulse disorder'
      t.boolean :sia, comment: 'suicidal ideation/attempt'
      t.boolean :sud, comment: 'substance Abuse Disorder'
      t.boolean :other_bh, comment: 'other behavioral health'
      t.boolean :coi, comment: 'cohort of interest'
      t.boolean :high_er, comment: '5+ ER Visits with No IP Psych Admission'
      t.boolean :psychoses, comment: '1+ Psychoses Admissions'
      t.boolean :other_ip_psych, comment: '+ IP Psych Admissions'
      t.boolean :high_util, comment: '3+ inpatient stays or 5+ emergency room visits throughout their claims experience'
      t.integer :er_visits
      t.integer :ip_admits
      t.integer :ip_admits_psychoses
      t.integer :antipsy_day
      t.integer :engaged_member_days
      t.integer :engaged_member_months
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
