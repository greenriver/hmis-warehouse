module Health
  class Goal::Housing < Goal::Base
    def self.type_name
      'Housing'
    end
  
    def to_partial_path
      "health/goal/clinicals/clinical"
    end
  end
end