module Health
  class Team::Member < HealthBase
    self.table_name = 'team_members'
    has_paper_trail class_name: Health::HealthVersion.name
    acts_as_paranoid

    belongs_to :team, class_name: Health::Team.name
    validates :email, presence: true, email_format: { check_mx: true }, length: {maximum: 250}
    validates_presence_of :first_name, :last_name, :organization

    def self.member_type_name
      raise 'Implement in sub-class'
    end

    def member_type_name
      self.class.member_type_name
    end

    def self.available_types
      [
        Health::Team::Provider,
        Health::Team::CaseManager,
        Health::Team::Nurse,
        Health::Team::Behavioral,
        Health::Team::Other,
      ]
    end

    def full_name
      ["#{first_name} #{last_name}", title].join(', ')
    end
  end
end

