module Health
  class CareplanFile < Health::HealthFile

    belongs_to :careplan, class_name: 'Health::Careplan', foreign_key: :parent_id

    def title
      "Careplan"
    end

  end
end