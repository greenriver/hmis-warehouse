module Health
  class ReleaseFormFile < Health::HealthFile

    belongs_to :release_form, class_name: 'Health::ReleaseForm', foreign_key: :parent_id

    def title
      'Release Form'
    end
  end
end