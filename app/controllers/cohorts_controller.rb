class CohortsController < ApplicationController
  include PjaxModalController
  include CohortAuthorization
  include CohortClients
  before_action :some_cohort_access!
  before_action :require_can_manage_cohorts!, only: [:create, :destroy, :edit, :update]
  before_action :require_can_access_cohort!, only: [:show]
  before_action :set_cohort, only: [:edit, :update, :destroy, :show]

  def index
    @cohort = cohort_source.new
    @cohorts = active_cohort_scope
    @inactive_cohorts = inactive_cohort_scope
  end

  def show
    params[:population] ||= :active
    load_cohort_names
    @cohort = cohort_scope.find(cohort_id)
    # leave off the pagination here and return all the data
    @cohort_clients = @cohort.search_clients(
      inactive:  params[:inactive],
      population: params[:population],
    )
    @cohort_client_updates = @cohort.cohort_clients.select(:id, :updated_at).map{|m| [m.id, m.updated_at.to_i]}.to_h
    @population = params[:population]
    respond_to do |format|
      format.html do
        @visible_columns = [CohortColumns::Meta.new]
        @visible_columns += @cohort.visible_columns
        if current_user.can_manage_cohorts? || current_user.can_edit_cohort_clients?
          @visible_columns << CohortColumns::Delete.new
        end
        @column_headers = @visible_columns.each_with_index.map do |col, index|
          header = {
            headerName: col.title,
            field: col.column,
            editable: col.column_editable? && col.editable,
          }
          header[:pinned] = :left if index <= @cohort.static_column_count
          case col.renderer
          when 'dropdown'
            # header.merge!({type: col.renderer, source: col.available_header})
            # Be more forgiving of drop-down data
            header.merge!({
              available_options: [''] + col.available_options,
              renderer: col.renderer,
            })
          when 'date', 'checkbox', 'text', 'numeric'
            header.merge!({renderer: col.renderer})
          else
            header.merge!({renderer: col.renderer})
          end
          header
        end
        @column_options =  @visible_columns.map do |m|
          options = {
            data: "#{m.column}.value"
          }
          if m.date_format.present?
            options[:dateFormat] = m.date_format
          end

          case m.renderer
          when 'dropdown'
            # options.merge!({type: m.renderer, source: m.available_options})
            # Be more forgiving of drop-down data
            options.merge!({type: 'autocomplete', source: m.available_options, strict: false, filter: false})
          when 'date', 'checkbox', 'text', 'numeric'
            options.merge!({type: m.renderer})
          else
            options.merge!({renderer: m.renderer})
            options.merge!({readOnly: true}) unless m.editable
          end
          options
        end
      end
      format.xlsx do
        headers['Content-Disposition'] = "attachment; filename=#{@cohort.sanitized_name}.xlsx"
      end
    end
  end

  def edit
    @assessment_types = [
      [ "Youth VI-SPDAT", GrdaWarehouse::Vispdat::Youth ],
      [ "Individual VI-SPDAT", GrdaWarehouse::Vispdat::Individual ],
      [ "Family VI-SPDAT", GrdaWarehouse::Vispdat::Family ],
    ]
  end

  def destroy
    @cohort.destroy
    redirect_to cohorts_path()
  end

  def create
    begin
      @cohort = cohort_source.create!(cohort_params)
      respond_with(@cohort, location: cohort_path(@cohort))
    rescue Exception => e
      flash[:error] = e.message
      redirect_to cohorts_path()
    end
  end

  def update
    cohort_options = cohort_params.except(:user_ids)
    user_ids = cohort_params[:user_ids].select(&:present?).map(&:to_i)
    @cohort.update(cohort_options)
    @cohort.update_access(user_ids)
    respond_with(@cohort, location: cohort_path(@cohort))
  end

  def cohort_params
    params.require(:grda_warehouse_cohort).permit(
      :name,
      :short_name,
      :effective_date,
      :visible_state,
      :days_of_inactivity,
      :default_sort_direction,
      :only_window,
      :active_cohort,
      :static_column_count,
      :show_on_client_dashboard,
      :visible_in_cas,
      :assessment_trigger,
      user_ids: []
    )
  end

  def cohort_id
    params[:id].to_i
  end

  def load_cohort_names
      @cohort_names ||= cohort_source.pluck(:id, :name, :short_name).
      map do |id, name, short_name|
        [id, short_name.presence || name]
      end.to_h
    end


  def flash_interpolation_options
    { resource_name: @cohort&.name }
  end

end
