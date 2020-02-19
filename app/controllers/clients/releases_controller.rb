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

    before_action :require_can_use_separated_consent!

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

    def pre_populated
      @coc_map = GrdaWarehouse::PublicFile.find_by(name: 'client/releases/coc_map')&.content
      respond_to do |format|
        format.html do
          render layout: false
        end
        format.pdf do
          render_pdf!
        end
      end
    end

    private def render_pdf!
      @pdf = true
      file_name = "Release of Information for #{@client.name}"
      send_data roi_pdf(file_name), filename: "#{file_name}.pdf", type: 'application/pdf'
    end

    private def roi_pdf(_file_name)
      grover_options = {
        display_url: root_url,
        displayHeaderFooter: true,
        headerTemplate: '<h2>Header</h2>',
        footerTemplate: '<h6 class="text-center">Footer</h6>',
        timeout: 50_000,
        format: 'Letter',
        emulate_media: 'print',
        margin: {
          top: '.5in',
          bottom: '.5in',
          left: '.4in',
          right: '.4in',
        },
        wait_until: 'networkidle0',
        # launch_args: ['--allow-file-access-from-files', '--enable-local-file-accesses'],
        # debug: {
        #   headless: false,
        #   devtools: true
        # },
      }

      html = render_to_string('clients/releases/pre_populated')
      Grover.new(html, grover_options).to_pdf
    end

    def file_source
      GrdaWarehouse::ClientFile.consent_forms
    end

    protected def title_for_show
      "#{@client.name} - Release of Information"
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

    private def permitted_params
      params.permit(
        :client_id,
        :effective_date,
        :selected_expiration_date,
        coc_codes: [],
      )
    end

    def selected_coc_codes
      permitted_params[:coc_codes]&.map(&:presence)&.compact || []
    end
    helper_method :selected_coc_codes

    def selected_effective_date
      permitted_params[:effective_date]
    end
    helper_method :selected_effective_date

    def selected_expiration_date
      permitted_params[:expiration_date]
    end
    helper_method :selected_expiration_date
  end
end
