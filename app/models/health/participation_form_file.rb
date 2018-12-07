# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health
  class ParticipationFormFile < Health::HealthFile

    belongs_to :participation_form, class_name: 'Health::ParticipationForm', foreign_key: :parent_id

    def title
      'Participation Form'
    end
  end
end