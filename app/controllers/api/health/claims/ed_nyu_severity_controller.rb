module Api::Health::Claims
  class EdNyuSeverityController < BaseController
    
    def load_data      
      @data = 'FIXME'
    end

    def source
      ::Health::Claims::EdNyuSeverity
    end
  end
end