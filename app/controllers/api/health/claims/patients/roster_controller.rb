module Api::Health::Claims::Patients
  class RosterController < BaseController
    
    def load_data      
      @data = 'FIXME'
    end

    def source
      ::Health::Claims::Roster
    end
  end
end