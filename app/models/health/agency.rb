module Health
  class Agency < HealthBase

    validates_presence_of :name

    has_many :relationships, class_name: 'Health::AgencyPatientReferral'
    has_many :assigned_patient_referrals, class_name: 'Health::PatientReferrals'

  end
end