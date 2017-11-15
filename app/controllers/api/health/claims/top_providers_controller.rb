module Api::Health::Claims
  class TopProvidersController < BaseController
    
    def load_data
      @data = source.group(:provider_name).
        sum(:indiv_pct).
        sort_by{|k,v| v}.
        reverse.
        first(5).map do |provider_name, indiv_pct|
          {
            provider_name: provider_name, 
            sdh_pct: indiv_pct / 100
          }
      end
    end

    def source
      ::Health::Claims::TopProviders
    end
  end
end