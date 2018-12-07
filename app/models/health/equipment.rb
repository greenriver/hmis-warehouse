# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Equipment < HealthBase
    acts_as_paranoid

    phi_patient :patient_id

    phi_attr :effective_date, Phi::Date
    phi_attr :provider, Phi::FreeText
    phi_attr :comments, Phi::FreeText

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