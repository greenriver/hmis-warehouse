module Health
  class Team::Member < HealthBase
    self.table_name = 'team_members'
    has_paper_trail class_name: Health::HealthVersion.name
    acts_as_paranoid

    # belongs_to :team, class_name: Health::Team.name
    belongs_to :patient
        
    validates :email, presence: true, email_format: { check_mx: true }, length: {maximum: 250}
    validates_presence_of :first_name, :last_name, :organization

    def self.member_type_name
      raise 'Implement in sub-class'
    end

    def member_type_name
      self.class.member_type_name
    end

    def self.class_from_member_type_name name
      return Health::Team::Provider if name == 'General'
      names = Hash[available_types.map(&:member_type_name).zip(available_types)]
      names[name] || Health::Team::Other
    end

    def self.available_types
      [
        Health::Team::Provider,
        Health::Team::PcpDesignee,
        Health::Team::CaseManager,
        Health::Team::Nurse,
        Health::Team::AcoCareManager,
        Health::Team::Behavioral,
        Health::Team::Representative,
        Health::Team::Other,
      ]
    end

    def self.icon_for(member_type_name)
      {
        'Behavioral Health' => ' icon-mental-health',
        'SDH Case Manager' => 'icon-helping-hands',
        'Nurse Care Manager' => 'icon-nurse-clipboard',
        'Other Important Contact' => 'icon-reminder',
        'Provider (MD/NP/PA)' => 'icon-medical-provider',
        'Designated Representative' => 'icon-users',
        'ACO Care Manager' => 'icon-nurse-clipboard',
        'PCP Designee' => 'icon-medical-provider',
      }[member_type_name]
    end

    def self.icon
      self.icon_for(self.member_type_name)
    end

    def full_name
      ["#{first_name} #{last_name}", title.presence].compact.join(', ')
    end

    def careplans
      Health::Careplan.
        where('responsible_team_member_id = ? OR provider_id = ? OR representative_id = ?', id, id, id)
    end

    def goals
      Health::Goal::Base.where('responsible_team_member_id = ?', id)
    end

    def in_use?
      careplans.any? || goals.any? 
    end
  end
end

