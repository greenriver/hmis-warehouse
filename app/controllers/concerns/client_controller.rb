module ClientController
  extend ActiveSupport::Concern
  
  included do
    include ArelHelper

    def sort_filter_index
      # sort / paginate
      at           = @clients.arel_table
      default_sort = at[sort_column.to_sym].send( sort_direction )
      sort = if client_processed_sort_columns.include?(sort_column)
        @clients = @clients.joins(:processed_service_history)
        at = GrdaWarehouse::WarehouseClientsProcessed.arel_table
        # nasty hack to prevent nulls from bubbling to the top
        c, ew = if sort_direction == 'asc'
          [ [at[sort_column.to_sym].eq(nil), 1 ], 0 ]
        else
          [ [at[sort_column.to_sym].eq(nil), 0 ], 1 ]
        end
        [ acase( [c], elsewise: ew ).send(sort_direction), at[sort_column.to_sym].send( sort_direction ) ]
      elsif sort_column == 'DOB'
        c, ew = if sort_direction == 'asc'
          [ [at[:DOB].eq(nil), 1], 0 ]
        else
          [ [at[:DOB].eq(nil), 0], 1 ]
        end
        [ acase( [c], elsewise: ew ).send(sort_direction), default_sort ]
      else
        [default_sort]
      end

      # Filter by date
      if params[:start_date].present? && params[:end_date].present? && params[:start_date].to_date < params[:end_date].to_date
        @start_date = params[:start_date].to_date
        @end_date = params[:end_date].to_date
        @clients = @clients.where(
            id: service_history_service_scope
              .select(:client_id)
              .distinct
              .where(date: (@start_date..@end_date))
        )
      end

      if params[:data_source_id].present?
        @data_source_id = params[:data_source_id].to_i
        @clients = @clients.joins(:warehouse_client_destination).where(warehouse_clients: {data_source_id: @data_source_id})
      end

      if params[:data_sharing].present? && params[:data_sharing] == '1'
        @clients = @clients.joins(:source_hmis_clients).where(hmis_clients: {consent_form_status: 'Signed fully'})
        @data_sharing = 1
      end

      @clients = @clients.order(*sort) if sort.any?
      @clients = @clients
        .preload(:processed_service_history, source_clients: :data_source)
        .page(params[:page]).per(50)

      @column = sort_column
      @direction = sort_direction
      @sort_columns = client_sort_columns + client_processed_sort_columns
      @active_filter = @data_source_id.present? || @start_date.present? || params[:data_sharing].present?
    end

    def title_for_show
      @client.full_name
    end
    alias_method :title_for_edit, :title_for_show
    alias_method :title_for_destroy, :title_for_show
    alias_method :title_for_update, :title_for_show
    alias_method :title_for_merge, :title_for_show
    alias_method :title_for_unmerge, :title_for_show

    def title_for_index
      'Client Search'
    end

    def new
      @existing_matches ||= []
      @client = client_source.new
    end
  
    def create
      existing_matches = look_for_existing_match(client_create_params)
      @bypass_search = false
      @client = client_source.new(client_create_params)
      if existing_matches.any? && ! client_create_params[:bypass_search].present?
        # Show the new page with the option to go to an existing client
        # add bypass_search as a hidden field so we don't end up here again
        # raise @existing_matches.inspect
        @bypass_search = true
        @existing_matches = client_source.where(id: existing_matches).
          joins(:warehouse_client_source).
          includes(:warehouse_client_source, :data_source)
        render action: :new
      elsif client_create_params[:bypass_search].present? || existing_matches.empty?
        # Create a new source and destination client
        # and redirect to the new client show page
        client_source.transaction do
          destination_ds_id = GrdaWarehouse::DataSource.destination.first.id
          @client.save
          @client.update(PersonalID: @client.id)
          destination_client = client_source.create(client_create_params.
            merge({
              data_source_id: destination_ds_id,
              PersonalID: @client.id
            }))
          warehouse_client = GrdaWarehouse::WarehouseClient.create(
            id_in_source: @client.id,
            source_id: @client.id,
            destination_id: destination_client.id,
            data_source_id: @client.data_source_id
          )
          if @client.persisted? && destination_client.persisted? && warehouse_client.persisted?
            flash[:notice] = "Client #{@client.full_name} created."
            if can_view_vspdat?
              redirect_to polymorphic_path(client_path_generator + [:vispdats], {client_id: destination_client.id})
            else
              redirect_to polymorphic_path(client_path_generator, {id: destination_client.id})
            end
          else
            flash[:error] = "Unable to create client"
            render action: :new
          end
        end
      end
    end

    def look_for_existing_match attr
      name_matches = client_source.source.
        where(
          nf('lower', [c_t[:FirstName]]).eq(attr[:FirstName].downcase).
          and(nf('lower', [c_t[:LastName]]).eq(attr[:LastName].downcase))
        ).
        pluck(:id)
      
      ssn_matches = []
      ssn = attr[:SSN].gsub('-','')
      if ::HUD.valid_social?(ssn)
        ssn_matches = client_source.source.
          where(c_t[:SSN].eq(ssn)).
          pluck(:id)
      end
      birthdate_matches = client_source.source.
        where(DOB: attr[:DOB]).
        pluck(:id)
      all_matches = ssn_matches + birthdate_matches + name_matches
      obvious_matches = all_matches.uniq.map{|i| i if (all_matches.count(i) > 1)}.compact
      if obvious_matches.any?
        return obvious_matches
      end
      return []
    end

    def client_create_params
      params.require(:client).
        permit(
          :FirstName,
          :MiddleName,
          :LastName,
          :SSN,
          :DOB,
          :bypass_search,
          :data_source_id
        )
    end

    # ajaxy method to render a particular rollup table
    def rollup
      @include_confidential_names = user_can_view_confidential_names?
      allowed_rollups = [
        "/clients/rollup/assessments",
        "/clients/rollup/assessments_without_data",
        "/clients/rollup/case_manager",
        "/clients/rollup/chronic",
        "/clients/rollup/contact_information",
        "/clients/rollup/demographics",
        "/clients/rollup/disability_types",
        "/clients/rollup/entry_assessments",
        "/clients/rollup/error",
        "/clients/rollup/exit_assessments",
        "/clients/rollup/family",
        "/clients/rollup/income_benefits",
        "/clients/rollup/ongoing_residential_enrollments",
        "/clients/rollup/other_enrollments",
        "/clients/rollup/residential_enrollments",
        "/clients/rollup/services",
        "/clients/rollup/services_full",
        "/clients/rollup/special_populations",
        "/clients/rollup/zip_details",
        "/clients/rollup/zip_map",
        "/clients/rollup/client_notes",
      ]
      rollup = allowed_rollups.find do |m|
        m == "/clients/rollup/" + params.require(:partial).underscore
      end

      raise 'Rollup not in whitelist' unless rollup.present?

      begin
        # if request.xhr?
          render partial: rollup, layout: false
        # end
      end
    end
    
    def create_note
      # type = note_params[:type]
      type = "GrdaWarehouse::ClientNotes::ChronicJustification"
      @note = GrdaWarehouse::ClientNotes::Base.new(note_params)
      begin
        raise "Note type not found" unless GrdaWarehouse::ClientNotes::Base.available_types.map(&:to_s).include?(type)
        @client.notes.create!(note_params.merge({user_id: current_user.id, type: type}))
        flash[:notice] = "Added new note"
        redirect_to action: :show
      rescue Exception => e
        @note.validate
        flash[:error] = "Failed to add note: #{e}"
        render :show
      end
    end
    
    # Only allow a trusted parameter "white list" through.
    private def note_params
      params.require(:note).
        permit(
          :note,
          :type,
        )
    end

    protected def set_client
      @client = client_scope.find(params[:id].to_i)
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
        'DOB'
      ]
    end

    protected def sort_column
      available_sort = client_processed_sort_columns + client_sort_columns
      available_sort.include?(params[:sort]) ? params[:sort] : 'LastName'
    end

    protected def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    protected def query_string
      "%#{@query}%"
    end
  end
end 
