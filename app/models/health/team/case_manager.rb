# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class Team::CaseManager < Team::Member

    def self.member_type_name
      'SDH Case Manager'
    end

  end
end

