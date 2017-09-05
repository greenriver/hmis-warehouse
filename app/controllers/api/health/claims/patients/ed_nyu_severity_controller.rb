module Api::Health::Claims::Patients
  class EdNyuSeverityController < BaseController
    
    def load_data      
      @data = begin
        individual = {group: @patient.client.name}
        sdh = {group: 'SDH Pilot'}
        scope.map do |row|
          individual[row.category] = row.indiv_pct
          sdh[row.category] = row.indiv_pct
        end
        [individual, sdh]
      end
    end

    def source
      ::Health::Claims::EdNyuSeverity
    end
  end
end