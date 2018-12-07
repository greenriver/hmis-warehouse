# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class Team::Provider < Team::Member

    def self.member_type_name
      'Provider (MD/NP/PA)'
    end
  end
end

