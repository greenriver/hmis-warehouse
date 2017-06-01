module Health
  class Careplan < HealthBase
    has_paper_trail
    acts_as_paranoid
    has_many :goals, class_name: Health::Goal::Base.name
    belongs_to :patient, class_name: Health::Patient.name
    belongs_to :user

  end
end