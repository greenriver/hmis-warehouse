###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AdHocDataSources::UploadsController < ApplicationController
  before_action :require_can_manage_some_ad_hoc_ds!
  before_action :set_data_source
  before_action :set_upload, only: [:show, :destroy, :download, :update]

  def new
    @upload = upload_source.new
  end

  def show
    @found_clients = GrdaWarehouse::Hud::Client.where(id: @upload.ad_hoc_clients.joins(:client).select(:client_id)).index_by(&:id)
    current_user.policy_context.preload_client_dependencies(@found_clients.keys)
    possible_client_ids = @upload.ad_hoc_clients.pluck(:matching_client_ids).flatten
    possible_matches = GrdaWarehouse::Hud::Client.where(id: possible_client_ids).index_by(&:id)
    @possible_matches = {}
    @upload.ad_hoc_clients.each do |ad_hoc_client|
      @possible_matches[ad_hoc_client.id] = possible_matches.values_at(*ad_hoc_client.matching_client_ids).compact
    end
  end

  def update
    update_health_prioritization
    update_client_ids
    respond_with(@upload, location: ad_hoc_data_source_upload_path(@data_source, @upload))
  end

  def download
    if params[:matched]
      @clients = @upload.ad_hoc_clients.where.not(client_id: nil)
      filename = "#{@upload.sanitized_name} - Matched Clients"
    elsif params[:all]
      @clients = @upload.ad_hoc_clients
      filename = "#{@upload.sanitized_name} - All Clients"
    else
      if @upload.batch_file.attached?
        filename = @upload.batch_file.filename.to_s
        send_data(@upload.batch_file.download, filename: filename, type: @upload.batch_file.content_type)
      else
        filename = @upload.sanitized_name
        send_data(@upload.file.read, filename: filename, type: @upload.file.content_type)
      end
      return
    end
    # Use the default render
    headers['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: "#{filename}.xlsx")
  end

  def destroy
    @upload.destroy
    respond_with(@upload, location: ad_hoc_data_source_path(@data_source))
  end

  def create
    @upload = upload_source.new(
      ad_hoc_data_source_id: @data_source.id,
      user_id: current_user.id,
      description: file_params[:description],
    )

    @upload.batch_file.attach(file_params[:batch_file]) if file_params[:batch_file].present?

    if @upload.save
      respond_with(@upload, location: ad_hoc_data_source_path(@data_source))
    else
      render :new
    end
  end

  private def file_params
    params.require(:grda_warehouse_ad_hoc_batch).
      permit(
        :batch_file,
        :description,
      )
  end

  private def update_health_prioritization
    prioritized_client_ids = update_params[:clients].select { |_, opts| opts[:health_prioritized] == '1' }.keys.map(&:to_i) & upload_client_ids
    un_prioritized_client_ids = update_params[:clients].select { |_, opts| opts[:health_prioritized] == '0' }.keys.map(&:to_i) & upload_client_ids
    GrdaWarehouse::Hud::Client.where(id: prioritized_client_ids).update_all(health_prioritized: 'Yes')
    GrdaWarehouse::Hud::Client.where(id: un_prioritized_client_ids).update_all(health_prioritized: nil)
  end

  # Warehouse clients tied to this upload: each row's matched client and its possible matches.
  private def upload_client_ids
    @upload_client_ids ||= (@upload.ad_hoc_clients.pluck(:client_id) + @upload.ad_hoc_clients.pluck(:matching_client_ids).flatten).compact.uniq
  end

  private def update_client_ids
    to_update = update_params[:clients].select { |_, opts| opts[:client_id].present? }
    assignable_ids = assignable_client_ids(to_update.values.map { |opts| opts[:client_id].to_i })
    to_update.each do |id, opts|
      next unless assignable_ids.include?(opts[:client_id].to_i)

      GrdaWarehouse::AdHocClient.where(id: id, ad_hoc_data_source_id: @data_source.id, batch_id: @upload.id).update_all(client_id: opts[:client_id])
    end
  end

  # Destination clients the user can find through client search or view directly. A row's
  # client_id also feeds upload_client_ids, which gates health prioritization.
  private def assignable_client_ids(client_ids)
    searchable = GrdaWarehouse::Hud::Client.destination_from_searchable_to(current_user).where(id: client_ids).pluck(:id)
    visible = GrdaWarehouse::Hud::Client.destination_visible_to(current_user).where(id: client_ids).pluck(:id)
    searchable | visible
  end

  private def update_params
    params.permit(
      clients: [
        :health_prioritized,
        :client_id,
      ],
    )
  end

  private def data_source_source
    GrdaWarehouse::AdHocDataSource
  end

  private def data_source_scope
    data_source_source.viewable_by(current_user)
  end

  private def set_data_source
    @data_source = data_source_scope.find(params[:ad_hoc_data_source_id].to_i)
  end

  private def set_upload
    @upload = @data_source.ad_hoc_batches.find(params[:id].to_i)
  end

  def upload_source
    GrdaWarehouse::AdHocBatch
  end

  def flash_interpolation_options
    { resource_name: 'Ad-Hoc Upload' }
  end
end
