module Health
  class Careplan < HealthBase
    
    acts_as_paranoid
    has_many :goals, class_name: Health::Goal::Base.name
    has_many :hpc_goals, class_name: Health::Goal::Hpc.name
    has_one :team, class_name: Health::Team.name, dependent: :destroy

    has_many :team_members, through: :team, source: :members
    belongs_to :patient, class_name: Health::Patient.name
    belongs_to :user

    belongs_to :responsible_team_member, class_name: Health::Team::Member
    belongs_to :provider, class_name: Health::Team::Member
    belongs_to :representative, class_name: Health::Team::Member

    attr_accessor :revising

    def revising
      @revising || false
    end

    # accepts_nested_attributes_for :goals
    # accepts_nested_attributes_for :team_members, reject_if: :all_blank, allow_destroy: true

    # Callbacks
    after_create :ensure_team_exists
    before_save :set_lock
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
      return if self.revising
      if team.blank?
        create_team!(patient: patient, editor: user)
      end
    end

    def set_lock
      return if self.revising
      if self.patient_signed_on.present? && self.provider_signed_on.present?
        self.locked = true
      else
        self.locked = false
      end
    end

    def revise!
      original_team = self.team
      original_team_members = self.team_members
      original_goals = self.goals

      new_careplan = self.class.new(revsion_attributes)
      self.class.transaction do
        new_careplan.revising = true
        new_careplan.locked = false
        new_careplan.save!
        team_attrs = original_team.attributes.except('id')
        team_attrs['careplan_id'] = new_careplan.id
        new_team = original_team.class.create(team_attrs)
        
        original_team_members.each do |member|
          member_attrs = member.attributes.except('id')
          member_attrs['team_id'] = new_team.id
          new_team_members = member.class.create(member_attrs)
        end
        original_goals.each do |goal|
          goal_attr = goal.attributes.except('id')
          goal_attr[:careplan_id] = new_careplan.id
          new_goal = goal.class.create(goal_attr)
        end
      end
      return new_careplan.id
    end

    def revsion_attributes
      attributes = self.attributes.except('id', 'patient_signed_on', 'responsible_team_member_signed_on', 'representative_signed_on', 'provider_signed_on')
      attributes['initial_date'] = Date.today
      attributes['review_date'] = Date.today + 6.months
      return attributes
    end
  end
end