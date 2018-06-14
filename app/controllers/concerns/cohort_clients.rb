module CohortClients
  extend ActiveSupport::Concern

  included do
    def set_cohort_clients
      if params[:inactive].present?
        @cohort_clients = @cohort.cohort_clients.joins(:client)
      else
        @cohort_clients = @cohort.cohort_clients.where(active: true).joins(:client)
      end
      
      @all_cohort_clients = @cohort_clients
      @show_housed = @all_cohort_clients.where.not(housed_date: nil, destination: [nil, '']).
        where(ineligible: [nil, false]).exists?
      @show_inactive = @all_cohort_clients.where(ineligible: true).exists?
      
      at = GrdaWarehouse::CohortClient.arel_table
      case params[:population]&.to_sym
      when :housed
        @cohort_clients = @cohort_clients.where.not(housed_date: nil, destination: [nil, '']).
          where(ineligible: [nil, false])          
      when :active
        @cohort_clients = @cohort_clients.where(at[:housed_date].eq(nil).or(at[:destination].eq(nil).or(at[:destination].eq('')))).
          where(ineligible: [nil, false])
      when :ineligible
        @cohort_clients = @cohort_clients.where(ineligible: true)
      else
        @cohort_clients = @cohort_clients.where(at[:housed_date].eq(nil).or(at[:destination].eq(nil).or(at[:destination].eq('')))).
          where(ineligible: [nil, false])
      end
    end

  end
end
