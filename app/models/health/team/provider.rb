module Health
  class Team::Provider < Team::Member
    
    def self.member_type_name
      'Provider (MD/NP/PA)'
    end
  end
end

