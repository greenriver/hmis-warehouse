module Api::Health::Claims
  class TopIpConditionsController < BaseController
    
    def load_data
      @data = source.group(:description).
        sum(:indiv_pct).
        sort_by{|k,v| v}.
        reverse.
        first(5).map do |description, indiv_pct|
          {
            description: description, 
            sdh_pct: indiv_pct / 100
          }
      end
    end

    def source
      ::Health::Claims::TopIpConditions
    end
  end
end