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
    
    def create_note
      # type = note_params[:type]
      type = "GrdaWarehouse::ClientNotes::ChronicJustification"
      @note = GrdaWarehouse::ClientNotes::Base.new(note_params)
      begin
        raise "Note type note found" unless GrdaWarehouse::ClientNotes::Base.available_types.map(&:to_s).include?(type)
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

    protected def client_source
      GrdaWarehouse::Hud::Client
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
