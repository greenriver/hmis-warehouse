module Health
  class Team::Other < Team::Member
    
    validates_presence_of :title
    def self.member_type_name
      'Other Important Contact'
    end

    def full_name
      "#{first_name} #{last_name} (#{title})"
    end
  end
end

