module Api::Health::Claims::Patients
  class AmountPaidController < BaseController
    
    def load_data      
      @data = group_by_date_and_sum_by_category(scope.order(year: :asc, month: :asc))
    end

    def source
      ::Health::Claims::AmountPaid
    end
  end
end