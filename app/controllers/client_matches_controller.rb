###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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
    @status = @possible_statuses.values.
      detect { |s| s == params['status'].to_s } || @possible_statuses.values.first

    # score are negative values (we present them as positive in the UI ) so to show better scores first use asc sort order
    ordering = if @status == 'candidate'
      { defer_count: :asc, score: :asc, id: :asc }
    else
      { updated_at: :desc }
    end

    @counts = client_match_scope.joins(:source_client, :destination_client).
      group(:status).count

    @matches = client_match_scope.where(status: @status).
      joins(source_client: :destination_client, destination_client: :destination_client).
      preload(
        destination_client: [
          :data_source,
          destination_client: :destination_client,
        ],
        source_client: [
          :data_source,
          destination_client: :destination_client,
        ],
      ).order(ordering)
    @pagy, @matches = pagy(@matches)

    client_ids = @matches.map do |m|
      [
        m.destination_client.destination_client&.id,
        m.source_client.destination_client&.id,
      ]
    end.flatten.compact
    @ongoing_enrollments = client_ids.map { |id| [id, Set[]] }.to_h
    GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: client_ids).entry.ongoing.
      joins(project: :organization).
      pluck(:client_id, :project_name, bool_or(p_t[:confidential], o_t[:confidential])).each do |client_id, project_name, confidential|
        @ongoing_enrollments[client_id] << GrdaWarehouse::Hud::Project.confidentialize_name(current_user, project_name, confidential)
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
    new_status = client_match_params.dig(:status)
    if new_status == 'accepted'
      @client_match.accept!(user: current_user)
    elsif new_status == 'rejected'
      @client_match.reject!(user: current_user)
    end

    respond_to do |format|
      format.json { render json: @client_match.as_json }
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
