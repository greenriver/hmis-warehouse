module Api::Health::Claims
  class TopProvidersController < BaseController
    
    def load_data
      @data = source.order(sdh_pct: :desc).
        select(:provider_name, :sdh_pct).
        distinct.
        limit(5).
        map do |row|
        row.attributes.with_indifferent_access.except(:id, :medicaid_id, :rank)
      end
    end

    def source
      ::Health::Claims::TopProviders
    end
  end
end