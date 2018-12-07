# ### HIPPA Risk Assessment
# Risk: None - contains no PHI
module Health
  class Equipment < HealthBase
    phi_attr :patient_referral_id, Phi::OtherIdentifier

    acts_as_paranoid

    has_many :careplans
    belongs_to :patient, required: true

    validates_presence_of :item
    validates :quantity, numericality: { only_integer: true, allow_blank: true }
    def self.available_items
      [
        'Diapers',
        'Pullups',
        'Liners',
        'Disposable Under pad /Chux',
        'Reusable bed size pad',
        'Reusable chair pad',
        'Enteral and Parenteral Formula',
        'Hearing Aid Batteries',
        'Prosthetics, Orthotics, and Orthopedic Footwear',
        'Other',
      ]
    end

    def self.available_stati
      [
        'Requested',
        'Active',
        'Expired',
        'Issue',
        'Denied',
      ]
    end

  end
end