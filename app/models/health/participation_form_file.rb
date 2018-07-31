module Health
  class ParticipationFormFile < Health::HealthFile

    belongs_to :participation_form, class_name: 'Health::ParticipationForm', foreign_key: :parent_id

    def title
      'Participation Form'
    end
  end
end