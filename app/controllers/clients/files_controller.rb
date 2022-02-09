###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class FilesController < ApplicationController
    include ClientPathGenerator
    include AjaxModalRails::Controller
    include ClientDependentControllers

    before_action :require_window_file_access!
    before_action :set_client
    before_action :set_files, only: [:index]
    before_action :set_window
    before_action :set_file, only: [:show, :update, :preview, :thumb, :has_thumb]

    # before_action :require_can_manage_client_files!, only: [:update]
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

    def show
      download
    end

    def new
      @file = file_source.new
    end

    def create
      @file = file_source.new
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
          coc_codes: allowed_params[:coc_codes].reject(&:blank?),
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

        # Keep various client fields in sync with files if appropriate
        @client.sync_cas_attributes_with_files
      rescue StandardError
        # flash[:error] = e.message
        render action: :new
        return
      end
      redirect_to action: :index
    end

    def update
      attrs = if can_confirm_housing_release?
        file_params
      elsif can_manage_client_files?
        file_params.except(:consent_form_confirmed)
      else
        not_authorized!
      end
      @client.invalidate_consent! if attrs[:consent_revoked_at].present? && @client.consent_form_id == @file.id

      if attrs.key?(:consent_form_signed_on)
        attrs[:effective_date] = attrs[:consent_form_signed_on]
        attrs[:consent_form_confirmed] = true if GrdaWarehouse::Config.get(:auto_confirm_consent)
      end
      @file.update(attrs)
    end

    def show_delete_modal
      @file = editable_scope.find(params[:id].to_i)
      @client = @file.client
    end

    def destroy
      @file = editable_scope.find(params[:id].to_i)
      @client = @file.client

      delete_params = params[:grda_warehouse_client_file]
      if delete_params
        delete_reason = delete_params[:delete_reason]
        if delete_reason.present?
          delete_detail = delete_params[:delete_detail]
          @file.update(delete_reason: delete_reason.to_i, delete_detail: delete_detail)
        end
      end

      begin
        # Mark file as deleted using the acts_as_paranoid field instead of calling @file.destroy! to prevent hooks from
        # firing which would cause acts_as_taggable to remove the associated tags
        @file.update(deleted_at: Time.now)

        flash[:notice] = 'File was successfully deleted.'
        # Keep various client fields in sync with files if appropriate
        @client.invalidate_consent! if @client.consent_form_id == @file.id
        # Remove any view caches for this client since permissions may have changed
        @client.clear_view_cache
        @client.sync_cas_attributes_with_files
      rescue Exception
        flash[:error] = 'File could not be deleted.'
      end
      redirect_to action: :index
    end

    def delete_reasons
      {
        0 => 'Incomplete Form',
        1 => 'Incorrect Client',
        2 => 'Incorrectly Categorized',
        99 => 'Other',
      }
    end
    helper_method :delete_reasons

    def preview
      if stale?(etag: @file, last_modified: @file.updated_at)
        @preview = @file.as_preview
        if @preview.blank?
          head(:ok)
          return
        end
        headers['Content-Security-Policy'] = "default-src 'none'; object-src 'self'; style-src 'unsafe-inline'; plugin-types application/pdf;"
        send_data @preview, filename: @file.name, disposition: :inline, content_type: @file.content_type
      else
        logger.debug 'used browser cache'
      end
    end

    def thumb
      if stale?(etag: @file, last_modified: @file.updated_at)
        @thumb = @file.as_thumb
        if @thumb.blank?
          head(:ok)
          return
        end
        headers['Content-Security-Policy'] = "default-src 'none'; object-src 'self'; style-src 'unsafe-inline'; plugin-types application/pdf;"
        send_data @thumb, filename: @file.name, disposition: :inline, content_type: @file.content_type
      else
        logger.debug 'used browser cache'
      end
    end

    def has_thumb # rubocop:disable Naming/PredicateName
      @thumb = @file.content_type == 'image/jpeg'
      if @thumb
        head(:ok)
      else
        head(:no_content)
      end
    end

    def download
      filename = @file.file&.file&.filename&.to_s || 'client_file'
      send_data(@file.content, type: @file.content_type, filename: filename)
    end

    def batch_download
      require 'rubygems'
      require 'zip'
      @files = all_file_scope.where(id: batch_params[:file_ids].split(',').map(&:to_i))

      # temp_file = Tempfile.new('tmp-zip-' + request.remote_ip)
      zip_stream = Zip::OutputStream.write_buffer do |zip_out|
        @files.each do |file|
          zip_out.put_next_entry(File.join(@client.id.to_s, "#{file.tag_list.join('-')}#{extension_for(file.content_type)}"))
          zip_out.print file.content
        end
      end
      zip_stream.rewind
      send_data zip_stream.read, type: 'application/zip', filename: "#{@client.id}_files.zip"

      # temp_file.close
      # redirect_to polymorphic_path(files_path_generator, client_id: @client.id)
    end

    def extension_for(mime_type)
      require 'rack/mime'
      @lookup ||= Rack::Mime::MIME_TYPES.invert
      @lookup[mime_type]
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

    def batch_params
      params.require(:batch_download).permit(:file_ids)
    end

    def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    def set_file
      @file = all_file_scope.find(params[:id].to_i)
    end

    def set_files
      @files = file_scope
    end

    def file_source
      GrdaWarehouse::ClientFile
    end

    protected def title_for_show
      "#{@client.name} - Files"
    end

    def window_visible?(visibility)
      return true if visibility.nil?

      visibility
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
        non_cache.
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
      @window = ! can_manage_client_files?
    end

    def editable_scope
      scope = file_source.editable_by?(current_user).
        where(client_id: @client.id)
      scope = scope.window unless can_manage_client_files?
      scope
    end

    def appropriate_file_path(options)
      client_file_path(options)
    end
    helper_method :appropriate_file_path

    def appropriate_delete_modal_path(options)
      show_delete_modal_client_file_path(options)
    end
    helper_method :appropriate_delete_modal_path
  end
end
