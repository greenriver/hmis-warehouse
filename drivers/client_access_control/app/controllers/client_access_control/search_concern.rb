###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::SearchConcern
  extend ActiveSupport::Concern
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  included do
    include ArelHelper

    def sort_filter_index
      # Filter by date
      if params[:start_date].present? && params[:end_date].present? && params[:start_date].to_date < params[:end_date].to_date
        @start_date = params[:start_date].to_date
        @end_date = params[:end_date].to_date
        @clients = @clients.where(
          id: service_history_service_scope.
            select(:client_id).
            distinct.
            where(date: (@start_date..@end_date)),
        )
      end

      # Filter by population for known populations
      if params[:population].present? && GrdaWarehouse::WarehouseReports::Dashboard::Base.available_sub_populations.value?(params[:population].to_sym)
        population = params[:population].to_sym
        @clients = @clients.public_send(population) if GrdaWarehouse::WarehouseReports::Dashboard::Base.available_sub_populations.value?(population)
      end

      if params[:data_source_id].present?
        @data_source_id = params[:data_source_id].to_i
        @clients = @clients.joins(:warehouse_client_destination).where(warehouse_clients: { data_source_id: @data_source_id })
      end

      vulnerability = params[:vulnerability]
      if vulnerability.present?
        vispdats = case vulnerability
        when 'low'
          GrdaWarehouse::Vispdat::Base.low_vulnerability
        when 'medium'
          GrdaWarehouse::Vispdat::Base.medium_vulnerability
        when 'high'
          GrdaWarehouse::Vispdat::Base.high_vulnerability
        else
          GrdaWarehouse::Vispdat::Base.all
        end
        @clients = @clients.joins(:vispdats).merge(vispdats.active)
      end

      age_group = params[:age_group]
      if age_group.present?
        group = GrdaWarehouse::Hud::Client.ahar_age_groups[age_group.to_sym]
        @clients = @clients.age_group(**group.slice(:start_age, :end_age))
      end

      if params[:data_sharing].present? && params[:data_sharing] == '1'
        @clients = @clients.full_housing_release_on_file
        @data_sharing = 1
      end
      @selected_sort = params[:sort]&.to_sym.presence || :best_match
      @clients = @clients.sort_by_option(@selected_sort)

      @sort_title = GrdaWarehouse::Hud::Client::SORT_OPTIONS[@selected_sort]
      @active_filter = @data_source_id.present? || @start_date.present? || params[:data_sharing].present? || params[:vulnerability].present? || params[:population].present? || age_group.present?
    end

    private def set_search_client
      id = params[:id].to_i
      # Search source clients only, this is faster
      @client = client_search_scope.find_by(id: id)
      return if @client.present?

      # search source clients for this destination if the id passed in isn't a source
      # if you can see any source client, you should be able to search for the destination (and get minimal access)
      destination = client_source.find_by(id: id)
      @client = destination if destination && client_search_scope.where(id: destination.source_client_ids).exists?
      return if @client.present?

      # for authoritative data sources, this can be the only way to
      # find someone since the data source doesn't have any projects
      @client = client_scope(id: id).find_by(id: id)
      return if @client.present?

      client_id = GrdaWarehouse::ClientMergeHistory.new.current_destination(id)
      if client_id
        redirect_to controller: controller_name, action: action_name, id: client_id
        return
      end

      # Throw a 404 by looking for a non-existent client
      # Using 0 here against the client model will be *much* faster than trying the search again
      @client = client_source.find(0)
    end

    private def query_string
      "%#{@query}%"
    end
  end
end
