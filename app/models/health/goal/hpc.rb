module Health
  class Goal::Hpc < Goal::Base
    def self.type_name
      'Goal'
    end

    def self.available_stati
      [
        'Identified',
        'In-progress',
        'Completed',
      ]
    end
  end
end