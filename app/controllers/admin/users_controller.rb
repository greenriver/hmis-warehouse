module Admin
  class UsersController < ApplicationController
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!
    after_action :log_user, only: [:show, :edit, :update, :destroy]
    helper_method :sort_column, :sort_direction

    require 'active_support'
    require 'active_support/core_ext/string/inflections'

    def index
      # search
      @users = if params[:q].present?
        user_scope.text_search(params[:q])
      else
        user_scope
      end

      # sort / paginate
      @users = @users
        .order(sort_column => sort_direction)
        .page(params[:page]).per(25)
    end

    def edit
      @user = user_scope.find(params[:id].to_i)
    end

    def update
      @user = user_scope.find(params[:id].to_i)
      existing_health_roles = @user.roles.health.to_a
      begin
        User.transaction do
          @user.update(user_params) 
          # Restore any health roles we previously had
          @user.roles = (@user.roles + existing_health_roles).uniq
          @user.set_viewables viewable_params
        end
      rescue Exception => e
        flash[:error] = 'Please review the form problems below'
        render :edit
        return
      end
      redirect_to({action: :index}, notice: 'User updated')
    end

    def destroy
      @user = user_scope.find params[:id]
      @user.destroy
      redirect_to({action: :index}, notice: 'User deleted')
    end

    def title_for_show
      @user.name
    end
    alias_method :title_for_edit, :title_for_show
    alias_method :title_for_destroy, :title_for_show
    alias_method :title_for_update, :title_for_show

    def title_for_index
      'User List'
    end

    private def user_scope
      User
    end

    private def user_params
      params.require(:user).permit(
        :last_name,
        :first_name,
        :email,
        :phone,
        :agency,
        :receive_file_upload_notifications,
        :notify_on_vispdat_completed,
        :notify_on_client_added,
        :notify_on_anomaly_identified,
        role_ids: [],
        coc_codes: [],
        contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role]
      )
    end

    private def viewable_params
      params.require(:user).permit(
        data_sources: [],
        organizations: [],
        projects: [],
        reports: [],
        cohorts: []
      )
    end

    private def sort_column
      user_scope.column_names.include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    private def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    private def log_user
      log_item(@user) if @user.present?
    end

    # some helpers factored out of a view for the sake of readability

    private def data_source_viewability(base)
      {
        selected:    @user.data_sources.map(&:id),
        input_html:  { class: 'jUserViewable', name: "#{base}[data_sources][]" },
        collection:  GrdaWarehouse::DataSource.viewable_by(current_user).order(:name),
        placeholder: 'Data Source',
        multiple:    true
      }
    end
    helper_method :data_source_viewability

    private def organization_viewability(base)
      model = GrdaWarehouse::Hud::Organization.viewable_by(current_user)
      collection = model
        .order(:name)
        .preload(:data_source)
        .group_by{ |o| o.data_source.name }
      {
        as:           :grouped_select,
        group_method: :last,
        selected:     @user.organizations.map(&:id),
        collection:   collection,
        placeholder:  'Organization',
        multiple:     true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[organizations][]"
        },
      }
    end
    helper_method :organization_viewability

    private def project_viewability(base)
      model = GrdaWarehouse::Hud::Project.viewable_by(current_user)
      collection = model
        .order(:name)
        .preload( :organization, :data_source )
        .group_by{ |p| "#{p.data_source&.name} / #{p.organization&.name}" }
      {
        as:           :grouped_select,
        group_method: :last,
        selected:     @user.projects.map(&:id),
        collection:   collection,
        placeholder:  'Project',
        multiple:     true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[projects][]"
        },
      }
    end
    helper_method :project_viewability

    private def coc_viewability(base)
      collection = %w[ ProjectCoc EnrollmentCoc ].flat_map do |c|
        "GrdaWarehouse::Hud::#{c}".constantize.distinct.pluck :CoCCode
      end.uniq.sort
      {
        label:       'CoC codes',
        selected:    @user.coc_codes,
        collection:  collection,
        placeholder: 'Project',
        multiple:    true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[coc_codes][]"
        },
      }
    end
    helper_method :coc_viewability

    private def reports_viewability(base)
      model = GrdaWarehouse::WarehouseReports::ReportDefinition.viewable_by(current_user)
      collection = model.order( :report_group, :name ).map do |rd|
        [ "#{rd.report_group}: #{rd.name}", rd.id ]
      end
      {
        selected:    @user.reports.map(&:id),
        collection:  collection,
        placeholder: 'Report',
        multiple:    true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[reports][]"
        },
      }
    end
    helper_method :reports_viewability

    private def cohort_viewability(base)
      model = GrdaWarehouse::Cohort.viewable_by(current_user)
      {
        selected:    @user.cohorts.map(&:id),
        collection:  model.order(:name),
        placeholder: 'Cohort',
        multiple:    true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[cohorts][]"
        },
      }
    end
    helper_method :cohort_viewability
  end
end
