module Health
  class Careplan < HealthBase
    
    acts_as_paranoid
    has_many :goals, class_name: Health::Goal::Base.name
    has_one :team, class_name: Health::Team.name, dependent: :destroy
    has_many :team_members, through: :team, source: :members
    belongs_to :patient, class_name: Health::Patient.name
    belongs_to :user

    # accepts_nested_attributes_for :goals
    # accepts_nested_attributes_for :team_members, reject_if: :all_blank, allow_destroy: true

    # Callbacks
    after_create :ensure_team_exists
    # End Callbacks 

    # Scopes
    scope :locked, -> do
      where(locked: true)
    end 
    scope :editable, -> do
      where(locked: false)
    end

    scope :approved, -> do
      where(status: :approved)
    end
    scope :rejected, -> do
      where(status: :rejected)
    end
    # End Scopes 

    # TODO
    def editable?
      ! locked
    end


    def ensure_team_exists
      if team.blank?
        create_team!(patient: patient, editor: user)
      end
    end

  end
end