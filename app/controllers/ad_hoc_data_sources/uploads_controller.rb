###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AdHocDataSources::UploadsController < ApplicationController
  before_action :require_can_manage_ad_hoc_data_sources!
  before_action :set_data_source
  before_action :set_upload, only: [:show, :destroy, :download, :update]

  def index
    attributes = upload_source.column_names - ['content', 'file']
    @uploads = @data_source.ad_hoc_batches.select(*attributes).
      page(params[:page].to_i).per(20).order(created_at: :desc)
  end

  def new
    @upload = upload_source.new
  end

  def show
    @found_clients = GrdaWarehouse::Hud::Client.where(id: @upload.ad_hoc_clients.joins(:client).select(:client_id)).index_by(&:id)
    possible_client_ids = @upload.ad_hoc_clients.pluck(:matching_client_ids).flatten
    possible_matches = GrdaWarehouse::Hud::Client.where(id: possible_client_ids).index_by(&:id)
    @possible_matches = {}
    @upload.ad_hoc_clients.each do |ad_hoc_client|
      @possible_matches[ad_hoc_client.id] = possible_matches.values_at(*ad_hoc_client.matching_client_ids).compact
    end
  end

  def update
    update_health_prioritization
    respond_with(@upload, location: ad_hoc_data_source_upload_path(@data_source, @upload))
  end

  def download
    send_data(@upload.content, filename: @upload.name, type: @upload.content_type)
  end

  def destroy
    @upload.destroy
    respond_with(@upload, location: ad_hoc_data_source_path(@data_source))
  end

  def create
    # NOTE: sometimes Excel likes to add BOMs.  We don't need those, and anything else that's in upper ASCII can go too
    clean_file = upload_params[:file]&.read
    clean_file = clean_file&.gsub(/[^[:ascii:]]/, '') if MimeMagic.by_magic(clean_file).blank?
    @upload = upload_source.create(upload_params.merge(ad_hoc_data_source_id: @data_source.id, content: clean_file, user_id: current_user&.id))
    respond_with(@upload, location: ad_hoc_data_source_path(@data_source))
  end

  private def update_health_prioritization
    prioritized_client_ids = update_params[:clients].select { |_, opts| opts[:health_prioritized] == '1' }.keys
    un_prioritized_client_ids = update_params[:clients].select { |_, opts| opts[:health_prioritized] == '0' }.keys
    GrdaWarehouse::Hud::Client.where(id: prioritized_client_ids).update_all(health_prioritized: true)
    GrdaWarehouse::Hud::Client.where(id: un_prioritized_client_ids).update_all(health_prioritized: false)
  end

  private def upload_params
    params.require(:grda_warehouse_ad_hoc_batch).
      permit(:file, :description)
  end

  private def update_params
    params.permit(clients: {})
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
    @upload = upload_source.find(params[:id].to_i)
  end

  def upload_source
    GrdaWarehouse::AdHocBatch
  end

  def flash_interpolation_options
    { resource_name: 'Ad-Hoc Upload' }
  end
end
