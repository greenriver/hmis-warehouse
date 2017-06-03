class DataSourcesController < ApplicationController
  before_action :require_can_view_imports!
  before_action :set_data_source, only: [:show, :update, :destroy]

  def index
    # search
    @data_sources = if params[:q].present?
      data_source_scope.text_search(params[:q])
    else
      data_source_scope
    end
    @data_sources = @data_sources.page(params[:page]).per(25)
  end

  def show
  end

  def new
    @data_source = data_source_source.new
  end

  def create
    @data_source = data_source_source.new(new_data_source_params)
    if @data_source.save
      flash[:notice] = "#{@data_source.name} created."
      redirect_to action: :index
    else
      flash[:error] = "Unable to create new #{data_source_source.model_name.human}"
      render action: :new
    end
  end

  def update
    error = false
    begin
      GrdaWarehouse::Hud::Project.transaction do
        @data_source.update!(visible_in_window: data_source_params[:visible_in_window] || false)
        data_source_params[:project_attributes].each do |id, project_attributes|
          if project_attributes[:act_as_project_type].present?
            act_as_project_type = project_attributes[:act_as_project_type].to_i
          end
          project = GrdaWarehouse::Hud::Project.find(id.to_i)
          project.act_as_project_type = act_as_project_type
          project.hud_continuum_funded = project_attributes[:hud_continuum_funded]
          project.project_cocs.each do |coc|
            coc.update(hud_coc_code: project_attributes[:hud_coc_code])
          end
          project.confidential = project_attributes[:confidential] || false
          if ! project.save
            error = true
          end
        end
      end
    rescue StandardError => e
      error = true
    end
    if error
      flash[:error] = "Unable to update data source. #{e}"
      render :show
    else
      redirect_to data_source_path(@data_source), notice: "Data Source updated"
    end
  end

  def destroy
    ds_name = @data_source.name
    if @data_source.has_data?
      flash[:error] = "Unable to delete #{ds_name}, there is data associated with it."
    else
      @data_source.destroy
      flash[:notice] = "Data Source: #{ds_name} was successfully destroyed."
    end
    redirect_to action: :index
  end

  private def data_source_params
    params.require(:data_source).
      permit(
        :visible_in_window,
        project_attributes: 
        [
          :act_as_project_type, 
          :hud_coc_code, 
          :hud_continuum_funded,
          :confidential,
        ]
      )
  end

  private def new_data_source_params
    params.require(:grda_warehouse_data_source).
      permit(
        :name, 
        :short_name, 
        :munged_personal_id, 
        :source_type,
        :visible_in_window,
      )
  end

  private def data_source_source
    GrdaWarehouse::DataSource
  end

  private def data_source_scope
    data_source_source.importable
  end

  private def set_data_source
    @data_source = data_source_source.find(params[:id].to_i)
  end
end