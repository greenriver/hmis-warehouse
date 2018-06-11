module CohortClients
  extend ActiveSupport::Concern

  included do
    def set_cohort_clients
      @cohort_clients = @cohort.search_clients(
        page: params[:page].to_i,
        per: params[:per].to_i,
        inactive:  params[:inactive],
        population: params[:population],
      )
    end
  end
end
