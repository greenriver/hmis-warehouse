module GrdaWarehouse
  class CohortCopier

    def initialize(cohort, cohort_scope, params)
      @columns = params[:columns]
      @copy_cohort_id = params[:cohort_id]
      @cohort_scope = cohort_scope
      @destination_cohort = cohort
      load_copy!
      load_destination!
    end

    def copy!
      success = true
      begin
        GrdaWarehouse::CohortClient.transaction do
          @destination_clients.each do |client|
            client.update_attributes(@to_copy_clients[client.client_id])
          end
        end
      rescue Exception => e
        success = false
      end
      return success
    end

    private

    def load_copy!
      @to_copy_cohort = @cohort_scope.find(@copy_cohort_id)
      @to_copy_clients = @to_copy_cohort.cohort_clients.
        where(client_id: destination_client_ids).
        select(select_columns).
        group_by{|c| c.client_id}
      @to_copy_clients.keys.each do |key|
        @to_copy_clients[key] = @to_copy_clients[key].first.
          attributes.reject{|k,v| k == 'client_id' || k == 'id'}
      end
    end

    def load_destination!
      @destination_clients = @destination_cohort.cohort_clients.
        where(client_id: @to_copy_clients.keys)
    end

    def destination_client_ids
      @destination_cohort.cohort_clients.map{|client| client.client_id}
    end

    def select_columns
      (@columns + ['client_id']).select{|c| c.present?}.join(', ')
    end

  end
end