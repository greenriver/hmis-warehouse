###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients
  class ReleasesController < FilesController
    include ClientPathGenerator
    include PjaxModalController
    include ClientDependentControllers

    before_action :require_window_file_access!
    before_action :set_client
    before_action :set_files, only: [:index]
    before_action :set_file, only: [:show, :update]

    after_action :log_client

    def index
      @consent_editable = consent_editable?
      @consent_form_url = GrdaWarehouse::PublicFile.url_for_location 'client/hmis_consent'
      @blank_files = GrdaWarehouse::PublicFile.known_hmis_locations.to_a.map do |location, title|
        { title: title, url: GrdaWarehouse::PublicFile.url_for_location(location) }
      end

      @consent_files = consent_scope
      @files = file_scope.page(params[:page].to_i).per(20).order(created_at: :desc)
      @deleted_files = all_file_scope.only_deleted

      @available_tags = GrdaWarehouse::AvailableFileTag.all.index_by(&:name)
      @pre_checked = params[:file_ids].split(',').map(&:to_i) if params[:file_ids].present?
    end

    def new
      @file = file_source.new
      @group_name = 'Release of Information'
      @consent_file_types = @file.class.available_tags[@group_name]
    end

    def file_params
      params.require(:grda_warehouse_client_file).
        permit(
          :file,
          :note,
          :visible_in_window,
          :consent_form_signed_on,
          :consent_form_confirmed,
          :effective_date,
          :expiration_date,
          :consent_revoked_at,
          coc_codes: [],
          tag_list: [],
        )
    end

    def consent_params
      params.require(:grda_warehouse_client_file).
        permit(
          :consent_form_confirmed,
        )
    end

    def file_source
      GrdaWarehouse::ClientFile.consent_forms
    end

    protected def title_for_show
      "#{@client.name} - Files"
    end

    def window_visible?(_visibility)
      true
    end

    def consent_editable?
      can_confirm_housing_release? || can_manage_client_files?
    end

    def all_file_scope
      scope = file_source.visible_by?(current_user).
        where(client_id: @client.id)
      scope = scope.window unless can_manage_client_files?
      scope
    end

    def file_scope
      scope = file_source.visible_by?(current_user).
        non_consent.
        where(client_id: @client.id)
      scope = scope.window unless can_manage_client_files?
      scope
    end

    def consent_scope
      scope = file_source.visible_by?(current_user).
        consent_forms.
        where(client_id: @client.id).
        order(
          consent_form_confirmed: :desc,
          consent_form_signed_on: :desc,
        )
      scope = scope.window unless can_manage_client_files?
      scope
    end

    def set_window
      @window = true
    end

    def editable_scope
      scope = file_source.editable_by?(current_user).
        where(client_id: @client.id)
      scope = scope.window unless can_manage_client_files?
      scope
    end
  end
end
