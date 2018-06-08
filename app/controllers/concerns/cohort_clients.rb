module CohortClients
  extend ActiveSupport::Concern

  included do
    def set_cohort_clients
      if params[:inactive].present?
        @cohort_clients = @cohort.cohort_clients
      else
        @cohort_clients = @cohort.cohort_clients.where(active: true)
      end
      
      @all_cohort_clients = @cohort_clients
      @show_housed = @all_cohort_clients.where.not(housed_date: nil).where(ineligible: [nil, false]).exists?
      @show_inactive = @all_cohort_clients.where(ineligible: true).exists?
      
      case params[:population]&.to_sym
        when :housed
          @cohort_clients = @cohort_clients.where.not(housed_date: nil).where(ineligible: [nil, false])
        when nil
          @cohort_clients = @cohort_clients.where(housed_date: nil, ineligible: [nil, false])
        when :active
          @cohort_clients = @cohort_clients.where(housed_date: nil, ineligible: [nil, false])
        when :ineligible
          @cohort_clients = @cohort_clients.where(ineligible: true)
      end
    end

  end
end
