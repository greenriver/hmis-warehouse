###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DataSourcesController < ApplicationController
  before_action :require_can_edit_projects!, only: [:update]
  before_action :require_can_edit_data_sources!, only: [:new, :create, :destroy, :edit, :update]
  before_action :require_can_view_imports_projects_or_organizations!, only: [:show, :index]
  before_action :set_data_source, only: [:show, :edit, :update, :destroy]
  before_action :load_hmis_hostname_options, only: [:new, :create, :edit, :update]

  def index
    # search
    @data_sources = if params[:q].present?
      data_source_scope.text_search(params[:q])
    else
      data_source_scope
    end
    @pagy, @data_sources = pagy(@data_sources.order(name: :asc))
    # @data_spans_by_id = GrdaWarehouse::DataSource.data_spans_by_id
    @client_counts = @data_sources.map { |ds| [ds.id, ds.client_count] }.to_h
    @project_counts = @data_sources.map { |ds| [ds.id, ds.project_count] }.to_h
  end

  def show
    @readonly = ! (can_edit_data_sources? || can_edit_projects?)
    load_overrides
    params[:coc_code] = nil unless valid_coc_code_param?
    @require_coc_choice = @data_source.require_coc_choice?(viewable_projects)
    if @require_coc_choice && params[:coc_code].blank?
      @coc_summaries = @data_source.coc_summaries(viewable_projects)
    else
      @organizations = load_organizations.to_a
      if @require_coc_choice
        @coc_display_name = params[:coc_code] == 'unknown' ? Translation.translate('Unknown CoC') : HudHelper.util.coc_name(params[:coc_code])
        @coc_project_count = project_scope.count
        @coc_org_count = @organizations.size
        @coc_project_types = @organizations.flat_map(&:projects).map(&:ProjectType).uniq
      else
        @project_types = @organizations.flat_map(&:projects).map(&:ProjectType).uniq
      end
    end
  end

  def new
    @data_source = data_source_source.new
    @per_page_js = ['data_source_form']
  end

  def create
    @data_source = data_source_source.new(new_data_source_params)
    @data_source.source_type = :authoritative if new_data_source_params[:authoritative]
    if @data_source.save
      @data_source.replace_access([current_user], scope: :editor)
      current_user.add_viewable(@data_source) # TODO: START_ACL remove when ACL transition complete
      flash[:notice] = "#{@data_source.name} created."
      redirect_to action: :index
    else
      @per_page_js = ['data_source_form']
      flash[:error] = Translation.translate('Unable to create new Data Source')
      render action: :new
    end
  end

  def edit
    @per_page_js = ['data_source_form']
  end

  def update
    if @data_source.update(data_source_params)
      redirect_to data_source_path(@data_source), notice: 'Data Source updated'
    else
      @per_page_js = ['data_source_form']
      flash[:error] = "Unable to update data source. #{@data_source.errors.full_messages.to_sentence}"
      render :edit
    end
  end

  def destroy
    name = @data_source.name
    DeleteItemJob.perform_later(item_id: @data_source.id, item_class: @data_source.class.name)
    flash[:notice] = "Data Source: #{name} was successfully queued for removal.  Please check back in a few minutes."

    redirect_to action: :index
  end

  private def load_hmis_hostname_options
    @available_hmis_hostnames = GrdaWarehouse::DataSource.available_hmis_hostnames(
      exclude_data_source_id: @data_source&.id,
    )
  end

  private def data_source_params
    permitted = params.require(:grda_warehouse_data_source).
      permit(
        :name,
        :short_name,
        :authoritative,
        :authoritative_type,
        :after_create_path,
        :visible_in_window,
        :import_paused,
        :disable_imports,
        :source_id,
        :munged_personal_id,
        :service_scannable,
        :obey_consent,
        :hmis,
        projects_attributes:
        [
          :id,
          :confidential,
          :after_create_path,
        ],
      )
    permitted.delete(:hmis) if @data_source.hmis?
    permitted
  end

  private def new_data_source_params
    params.require(:grda_warehouse_data_source).
      permit(
        :name,
        :short_name,
        :munged_personal_id,
        :source_type,
        :visible_in_window,
        :authoritative,
        :authoritative_type,
        :after_create_path,
        :import_paused,
        :disable_imports,
        :source_id,
        :service_scannable,
        :obey_consent,
        :hmis,
      )
  end

  private def data_source_source
    GrdaWarehouse::DataSource.viewable_by current_user
  end

  private def data_source_scope
    data_source_source.source
  end

  private def set_data_source
    @data_source = data_source_source.find(params[:id].to_i)
  end

  private def load_overrides
    @overrides = HmisCsvImporter::ImportOverride.
      where(data_source: @data_source).
      sorted
  end

  private def load_organizations
    p_t = GrdaWarehouse::Hud::Project.arel_table
    o_t = GrdaWarehouse::Hud::Organization.arel_table
    @data_source.organizations.
      eager_load(:data_source, projects: :data_source).
      merge(project_scope).
      order(o_t[:OrganizationName].asc, p_t[:ProjectName].asc)
  end

  # 'unknown' is this feature's own bucket for projects with a blank/whitespace CoC
  # code (see GrdaWarehouse::DataSource#coc_summaries), not a real HUD CoC code.
  private def valid_coc_code_param?
    params[:coc_code].blank? || params[:coc_code] == 'unknown' || HudHelper.util.valid_coc?(params[:coc_code])
  end

  private def viewable_projects
    @viewable_projects ||= GrdaWarehouse::Hud::Project.viewable_by(
      current_user,
      confidential_scope_limiter: :all,
      permission: :can_view_projects,
    )
  end

  private def project_scope
    coc_code = params[:coc_code]
    return viewable_projects if coc_code.blank?

    # Subquery so ProjectCoC joins stay off the Organization query.
    matching = if coc_code == 'unknown'
      GrdaWarehouse::Hud::Project.joins(:project_cocs).merge(GrdaWarehouse::Hud::ProjectCoc.unknown_coc)
    else
      GrdaWarehouse::Hud::Project.in_coc(coc_code: coc_code)
    end
    viewable_projects.where(id: matching.select(:id))
  end
end
