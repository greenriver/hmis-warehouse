module Health
  class Team < HealthBase
    has_paper_trail
    acts_as_paranoid
    has_many :members, class_name: Health::Team::Member.name
    belongs_to :patient
    belongs_to :editor, class_name: User.name, foreign_key: :user_id

  end
end