# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class Goal::Social < Goal::Base
    def self.type_name
      'Social'
    end

  end
end