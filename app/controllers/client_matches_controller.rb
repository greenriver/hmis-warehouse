###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ClientMatchesController < ApplicationController
  before_action :require_can_edit_clients!
  include ClientPathGenerator
  helper ClientMatchHelper

  def index
    @possible_statuses = {
      'Candidates' => 'candidate',
      'Accepted' => 'accepted',
      'Rejected' => 'rejected',
    }
    @status = @possible_statuses.values.detect { |s| s == params['status'].to_s } || @possible_statuses.values.first

    # score are negative values (we present them as positive in the UI ) so to show better scores first use asc sort order
    ordering = {
      'candidate' => { defer_count: :asc, score: :asc, id: :asc },
    }[@status] || { updated_at: :desc }

    @counts = client_match_scope.joins(:source_client, :destination_client).group(:status).count

    @matches = client_match_scope.where(status: @status).
      joins(:source_client, :destination_client).
      preload(
        destination_client: [
          :data_source,
          destination_client: :destination_client,
        ],
        source_client: [
          :data_source,
          destination_client: :destination_client,
        ],
      ).order(ordering).page(params[:page])

    client_ids = @matches.map { |m| [m.destination_client.destination_client.id, m.source_client.destination_client.id] }.flatten
    @ongoing_enrollments = client_ids.map { |id| [id, []] }.to_h
    GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: client_ids).entry.ongoing.
      pluck(:client_id, :project_name).each do |row|
        @ongoing_enrollments[row.first] << row.last
      end
  end

  def defer
    @matches = if params[:destination_client_id]
      client_match_scope.where(destination_client_id: params[:destination_client_id].to_s)
    else
      client_match_scope.where(id: params.require(:id))
    end
    @matches.transaction do
      @matches.each do |m|
        m.increment!(:defer_count)
      end
    end
    respond_to do |format|
      format.json { render status: 204 }
      format.html { redirect_to(request.referrer.presence || match_clients.path) }
    end
  end

  def update
    @client_match = client_match_scope.find(params[:id])
    @client_match.updated_by_id = current_user.id
    @client_match.update_attributes(client_match_params)

    if @client_match.accepted?
      dst = @client_match.destination_client.destination_client
      src = @client_match.source_client
      dst.merge_from(src, reviewed_by: current_user, reviewed_at: @client_match.updated_at, client_match_id: @client_match.id)
      Importing::RunAddServiceHistoryJob.perform_later
    end

    respond_to do |format|
      format.json { render json: @client_match.as_json(methods: [:source_group_id]) }
      format.html { redirect_to(request.referrer.presence || match_clients.path) }
    end
  rescue ActiveRecord::StaleObjectError
    @client_match.errors[:base] = 'Another user has made a change to this record'
  end

  private def client_match_params
    params.require(:client_match).permit(:status)
  end

  private def client_match_scope
    GrdaWarehouse::ClientMatch
  end
end
