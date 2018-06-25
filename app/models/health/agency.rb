module Health
  class Agency < HealthBase
    acts_as_paranoid
    validates_presence_of :name

    has_many :relationships, class_name: 'Health::AgencyPatientReferral', dependent: :destroy
    has_many :assigned_patient_referrals, class_name: 'Health::PatientReferrals'
    has_many :agency_users, class_name: 'Health::AgencyUser'
    
    def users
      User.where(id: (agency_users||[]).map{|au| au.user_id})
    end

  end
end