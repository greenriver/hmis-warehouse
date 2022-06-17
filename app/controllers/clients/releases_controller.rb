###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class ReleasesController < FilesController
    include ClientPathGenerator
    include AjaxModalRails::Controller
    include ClientDependentControllers

    skip_before_action :require_window_file_access!
    before_action :require_can_use_separated_consent!

    after_action :log_client

    def index
      @consent_editable = consent_editable?
      @consent_form_url = GrdaWarehouse::PublicFile.url_for_location 'client/hmis_consent'
      @blank_files = GrdaWarehouse::PublicFile.known_hmis_locations.to_a.map do |location, title|
        { title: title, url: GrdaWarehouse::PublicFile.url_for_location(location) }
      end

      @consent_files = consent_scope
      @deleted_files = all_file_scope.only_deleted

      @available_tags = GrdaWarehouse::AvailableFileTag.all.index_by(&:name)
      @pre_checked = params[:file_ids].split(',').map(&:to_i) if params[:file_ids].present?
    end

    def new
      @file = file_source.new
      @group_name = 'Release of Information'
      @consent_file_types = file_source.available_tags[@group_name]
    end

    def create
      @file = file_source.new
      @group_name = 'Release of Information'
      @consent_file_types = file_source.available_tags[@group_name]
      @file.errors.add :tag_list, 'You must specify file contents' if file_params[:tag_list].blank?
      @file.errors.add :file, 'No uploaded file found' unless file_params[:file]
      if @file.errors.any?
        render :new
        return
      end

      begin
        allowed_params = current_user.can_confirm_housing_release? ? file_params : file_params.except(:consent_form_confirmed)
        file = allowed_params[:file]
        tag_list = [allowed_params[:tag_list]].select(&:present?)
        attrs = {
          file: file,
          client_id: @client.id,
          user_id: current_user.id,
          # content_type: file&.content_type,
          content: file&.read,
          note: allowed_params[:note],
          name: file.original_filename,
          visible_in_window: window_visible?(allowed_params[:visible_in_window]),
          effective_date: allowed_params[:effective_date],
          expiration_date: allowed_params[:expiration_date],
          consent_form_confirmed: allowed_params[:consent_form_confirmed] || GrdaWarehouse::Config.get(:auto_confirm_consent),
          coc_codes: allowed_params[:coc_codes]&.reject(&:blank?) || [],
          consent_revoked_at: allowed_params[:consent_revoked_at],
        }

        @file.assign_attributes(attrs)
        @file.tag_list.add(tag_list)

        requires_effective_date = GrdaWarehouse::AvailableFileTag.where(name: @file.tag_list).any?(&:requires_effective_date)
        requires_expiration_date = GrdaWarehouse::AvailableFileTag.where(name: @file.tag_list).any?(&:requires_expiration_date)

        if requires_effective_date && requires_expiration_date
          @file.save!(context: :requires_expiration_and_effective_dates)
        elsif requires_effective_date
          @file.save!(context: :requires_effective_date)
        elsif requires_expiration_date
          @file.save!(context: :requires_expiration_date)
        else
          @file.save!
        end
        # Remove any view caches for this client since permissions may have changed
        @client.clear_view_cache
        # Keep various client fields in sync with files if appropriate
        @client.sync_cas_attributes_with_files
      rescue StandardError
        # flash[:error] = e.message
        render action: :new
        return
      end
      redirect_to client_releases_path
    end

    def update
      attrs = if can_confirm_housing_release?
        file_params
      elsif can_manage_client_files? || can_use_separated_consent?
        file_params.except(:consent_form_confirmed)
      else
        not_authorized!
      end
      @client.invalidate_consent! if attrs[:consent_revoked_at].present? && @client.consent_form_id == @file.id
      # Remove any view caches for this client since permissions may have changed
      @client.clear_view_cache

      if attrs.key?(:consent_form_signed_on)
        attrs[:effective_date] = attrs[:consent_form_signed_on]
        attrs[:consent_form_confirmed] = true if GrdaWarehouse::Config.get(:auto_confirm_consent)
      end
      @file.update(attrs)
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
      true
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
      return ['None'] if params[:refused].present?

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

    def appropriate_file_path(options)
      client_release_path(options)
    end

    def appropriate_delete_modal_path(options)
      show_delete_modal_client_release_path(options)
    end
  end
end
