###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientController
  extend ActiveSupport::Concern
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  included do
    include ArelHelper

    def sort_filter_index
      # sort / paginate
      default_sort = c_t[:LastName].asc
      nulls_last = ' NULLS LAST' if ActiveRecord::Base.connection.adapter_name.in?(['PostgreSQL', 'PostGIS'])
      sort = if client_processed_sort_columns.include?(sort_column)
        @clients = @clients.joins(:processed_service_history).includes(:processed_service_history)
        [wcp_t[sort_column.to_sym].send(sort_direction).to_sql + nulls_last.to_s, default_sort]
      elsif sort_column == 'DOB'
        [c_t[sort_column.to_sym].send(sort_direction).to_sql + nulls_last.to_s, default_sort]
      else
        [c_t[sort_column.to_sym].send(sort_direction)]
      end

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

      # Filter by population with whitelist
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
        @clients = @clients.age_group(group.slice(:start_age, :end_age))
      end

      if params[:data_sharing].present? && params[:data_sharing] == '1'
        @clients = @clients.full_housing_release_on_file
        @data_sharing = 1
      end

      @clients = @clients.order(*sort) if sort.any?

      @column = sort_column
      @direction = sort_direction
      @sort_columns = client_sort_columns + client_processed_sort_columns
      @active_filter = @data_source_id.present? || @start_date.present? || params[:data_sharing].present? || params[:vulnerability].present? || params[:population].present? || age_group.present?
    end

    def title_for_index
      'Client Search'
    end

    def validate_new_client_params(clean_params)
      valid = true
      unless [0, 9].include?(clean_params[:SSN].length)
        @client.errors.add(:SSN, :format, message: 'must contain 9 digits')
        valid = false
      end
      if clean_params[:FirstName].blank?
        @client.errors.add(:FirstName, :required, message: 'is required')
        valid = false
      end
      if clean_params[:LastName].blank?
        @client.errors.add(:LastName, :required, message: 'is required')
        valid = false
      end
      if clean_params[:DOB].blank?
        @client.errors.add(:DOB, :required, message: 'Date of birth is required')
        valid = false
      end
      valid
    end

    def look_for_existing_match(attr)
      name_matches = client_search_scope.
        where(
          nf('lower', [c_t[:FirstName]]).eq(attr[:FirstName].downcase).
          and(nf('lower', [c_t[:LastName]]).eq(attr[:LastName].downcase)),
        ).
        pluck(:id)

      ssn_matches = []
      ssn = attr[:SSN].delete('-')
      if ::HUD.valid_social?(ssn)
        ssn_matches = client_search_scope.
          where(c_t[:SSN].eq(ssn)).
          pluck(:id)
      end
      birthdate_matches = client_search_scope.
        where(DOB: attr[:DOB]).
        pluck(:id)
      all_matches = ssn_matches + birthdate_matches + name_matches
      obvious_matches = all_matches.uniq.map { |i| i if all_matches.count(i) > 1 }.compact
      return obvious_matches if obvious_matches.any?

      []
    end

    def client_create_params
      params.require(:client).
        permit(
          :FirstName,
          :MiddleName,
          :LastName,
          :SSN,
          :DOB,
          :VeteranStatus,
          :bypass_search,
          :data_source_id,
          Gender: [],
        )
    end

    # @return [Boolean] false if the id is obsolete and a redirect was required
    protected def set_client
      # Do we have this client?
      # If we don't, attempt to redirect to the most recent version
      # If there's not merge path, just force an active record not found
      # This query is slow, even as an exists query, so just attempt to load the client
      # Sometimes we have a client_id (when dealing with sub-pages) so check for that first
      id = params[:client_id].presence || params[:id].to_i
      @client = client_scope(id: id).find_by(id: id)
      return true if @client.present?

      client_id = GrdaWarehouse::ClientMergeHistory.new.current_destination(id)
      if client_id
        redirect_to controller: controller_name, action: action_name, id: client_id
        return false
      end

      # Throw a 404 by looking for a non-existent client
      # Using 0 here against the client model will be *much* faster than trying the search again
      @client = client_source.find(0)
    end

    protected def set_search_client
      id = params[:id].to_i
      # Search source clients only, this is faster
      @client = client_search_scope.find_by(id: id)
      return if @client.present?

      # search source and destination clients
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

    protected def set_client_start_date
      @start_date = @client.date_of_first_service
    end

    protected def client_processed_sort_columns
      @client_processed_sort_columns ||= [
        'days_served',
        'first_date_served',
        'last_date_served',
      ]
    end

    protected def client_sort_columns
      @client_sort_columns ||= [
        'LastName',
        'FirstName',
        'DOB',
      ]
    end

    protected def sort_column
      available_sort = client_processed_sort_columns + client_sort_columns
      available_sort.include?(params[:sort]) ? params[:sort] : 'LastName'
    end

    protected def sort_direction
      ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'asc'
    end

    protected def query_string
      "%#{@query}%"
    end
  end
end
