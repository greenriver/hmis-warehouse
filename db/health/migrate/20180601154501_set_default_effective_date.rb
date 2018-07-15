class SetDefaultEffectiveDate < ActiveRecord::Migration
  def up
    Health::PatientReferral.all.each do |pr|
      pr.update(effective_date: pr.created_at)
    end
    execute("ALTER TABLE patient_referrals ALTER COLUMN effective_date SET DEFAULT CURRENT_TIMESTAMP")
    
  end
end
