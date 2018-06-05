class CohortsController < ApplicationController
  include PjaxModalController
  include CohortAuthorization
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
    load_cohort_names
    cohort_with_preloads = cohort_scope.where(id: cohort_id).
      preload(cohort_clients: [:cohort_client_notes, {client: :processed_service_history}])
    # missing_document_state = @cohort.column_state.detect{|m| m.class == ::CohortColumns::MissingDocuments}
    @cohort = cohort_with_preloads.first
    
    if params[:inactive].present?
      case params[:population]&.to_sym
        when :housed
          @cohort_clients = @cohort.cohort_clients.joins(:client).where.not(housed_date: nil).where(ineligible: [nil, false])
        when :active
          @cohort_clients = @cohort.cohort_clients.joins(:client).where(housed_date: nil, ineligible: [nil, false])
        when :ineligible
          @cohort_clients = @cohort.cohort_clients.joins(:client).where(ineligible: true)
      end
    else    
      case params[:population]&.to_sym
        when :housed
          @cohort_clients = @cohort.cohort_clients.joins(:client).where(active: true).where.not(housed_date: nil).where(ineligible: [nil, false])
        when :active
          @cohort_clients = @cohort.cohort_clients.joins(:client).where(active: true).where(housed_date: nil, ineligible: [nil, false])
        when :ineligible
          @cohort_clients = @cohort.cohort_clients.joins(:client).where(active: true).where(ineligible: true)
      end
    end
    @cohort_client_updates = @cohort.cohort_clients.map{|m| [m.id, m.updated_at.to_i]}.to_h
    @population = params[:population]
    respond_to do |format|
      format.html do
        @visible_columns = [CohortColumns::Meta.new]
        @visible_columns += @cohort.visible_columns
        if current_user.can_manage_cohorts? || current_user.can_edit_cohort_clients?
          @visible_columns << CohortColumns::Delete.new
        end
        @column_headers = @visible_columns.map(&:title)
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
        headers['Content-Disposition'] = "attachment; filename=#{@cohort.name}.xlsx"
      end
    end
  end

  def edit

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
      user_ids: []
    )
  end

  def cohort_id
    params[:id].to_i
  end

  def load_cohort_names
      @cohort_names = cohort_source.pluck(:id, :name, :short_name).
      map do |id, name, short_name|
        [id, short_name.presence || name]
      end.to_h
    end

  
  def flash_interpolation_options
    { resource_name: @cohort&.name }
  end

end
