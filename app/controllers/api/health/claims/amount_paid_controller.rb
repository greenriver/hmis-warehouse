module Api::Health::Claims
  class AmountPaidController < BaseController
    
    def load_data      
      @data = group_by_date_and_sum_by_category(source.order(year: :asc, month: :asc))
    end

    def source
      ::Health::Claims::AmountPaid
    end
  end
end