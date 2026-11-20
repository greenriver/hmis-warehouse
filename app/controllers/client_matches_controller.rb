###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientMatchesController < ApplicationController
  before_action :require_can_edit_clients!
  include ClientPathGenerator
  include ArelHelper
  helper ClientMatchHelper

  SCAN_BATCH_SIZE = 1_000
  SCAN_LIMIT = 20_000

  def index
    @possible_statuses = {
      'Candidates' => 'candidate',
      'Accepted' => 'accepted',
      'Rejected' => 'rejected',
    }
    @status = @possible_statuses.values.
      detect { |s| s == params['status'].to_s } || @possible_statuses.values.first

    # score are negative values (we present them as positive in the UI ) so to show better scores first use asc sort order
    # defer_count is NULL until a match is first deferred, and those matches come first.
    ordering = if @status == 'candidate'
      cm_t = GrdaWarehouse::ClientMatch.arel_table
      [cm_t[:defer_count].asc.nulls_first, cm_t[:score].asc, cm_t[:id].asc]
    else
      { updated_at: :desc, id: :desc }
    end

    # Totals cover every listable match, whoever can open it, so they stay cheap for users who
    # can search most clients.
    @counts = listable_matches.group(:status).count
    @counts_include_hidden_matches = !current_user.legacy_can_search_across_all_clients?

    @pagy = Pagy::Countless.new(page: pagy_get_page({}), overflow: :empty_page)
    page_rows = visible_match_page(GrdaWarehouse::ClientMatch.where(status: @status).order(ordering), @pagy)
    @pagy.finalize(page_rows.size)
    @matches = page_rows.first(@pagy.items)
    current_user.policy_context.preload_client_dependencies(@matches.flat_map { |m| [m.destination_client_id, m.source_client_id] })

    client_ids = @matches.map do |m|
      [
        m.destination_client.destination_client&.id,
        m.source_client.destination_client&.id,
      ]
    end.flatten.compact
    @ongoing_enrollments = client_ids.map { |id| [id, []] }.to_h
    GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: client_ids).entry.ongoing.
      joins(project: :organization).
      merge(GrdaWarehouse::Hud::Project.viewable_by(current_user, permission: :can_view_clients, confidential_scope_limiter: :all)).
      pluck(:client_id, :project_name, bool_or(p_t[:confidential], o_t[:confidential])).each do |client_id, project_name, confidential|
        @ongoing_enrollments[client_id] << GrdaWarehouse::Hud::Project.confidentialize_name(current_user, project_name, confidential)
      end
  end

  def defer
    @matches = if params[:destination_client_id]
      client_match_scope(GrdaWarehouse::ClientMatch.where(destination_client_id: params[:destination_client_id].to_s))
    else
      client_match_scope(GrdaWarehouse::ClientMatch.where(id: params.require(:id)))
    end
    @matches.transaction do
      @matches.each do |m|
        m.increment!(:defer_count)
      end
    end
    respond_to do |format|
      format.json { render status: 204 }
      format.html { redirect_to(request.referrer.presence || client_matches_path) }
    end
  end

  def update
    @client_match = client_match_scope(GrdaWarehouse::ClientMatch.where(id: params[:id])).take!
    new_status = client_match_params.dig(:status)
    saved = if new_status == 'accepted'
      @client_match.accept!(user: current_user)
    elsif new_status == 'rejected'
      @client_match.reject!(user: current_user)
    elsif new_status == 'candidate' && @client_match.rejected?
      @client_match.flag_as(user: current_user, status: 'candidate')
    else
      true
    end
    return head(:conflict) unless saved

    respond_to do |format|
      format.json { render json: { id: @client_match.id, status: @client_match.status } }
      format.html { redirect_to(request.referrer.presence || client_matches_path) }
    end
  rescue ActiveRecord::StaleObjectError
    head(:conflict)
  end

  private def client_match_params
    params.require(:client_match).permit(:status)
  end

  # The page's matches plus one more, so pagy can tell whether a next page exists.
  private def visible_match_page(matches, pagy)
    matches = listable_matches(matches)
    listing = matches.preload(
      destination_client: [:data_source, destination_client: :destination_client],
      source_client: [:data_source, destination_client: :destination_client],
    )
    return listing.offset(pagy.offset).limit(pagy.items + 1).to_a if current_user.legacy_can_search_across_all_clients?

    visible_ids = scanned_visible_match_ids(matches, pagy.offset + pagy.items + 1)
    return listing.where(id: visible_ids.drop(pagy.offset)).to_a if visible_ids

    client_match_scope.merge(listing).offset(pagy.offset).limit(pagy.items + 1).to_a
  end

  # Matches the list can show: both clients exist and each has a warehouse destination client.
  private def listable_matches(matches = GrdaWarehouse::ClientMatch.all)
    matches.joins(source_client: :destination_client, destination_client: :destination_client)
  end

  # Ids of the first `wanted` matches, in display order, whose clients are both searchable.
  # Checking a batch's clients stays fast however broad the user's access is, unlike building
  # the user's whole searchable set. Returns nil when SCAN_LIMIT matches were checked without
  # finding `wanted`; the caller then builds the searchable set, which is small for such users.
  private def scanned_visible_match_ids(matches, wanted)
    rows = matches.limit(SCAN_LIMIT).pluck(:id, :source_client_id, :destination_client_id)
    visible_ids = []
    rows.each_slice(SCAN_BATCH_SIZE) do |batch|
      client_ids = batch.flat_map { |_, source_id, destination_id| [source_id, destination_id] }.uniq
      searchable = GrdaWarehouse::Hud::Client.searchable_to(current_user, client_ids: client_ids).pluck(:id).to_set
      batch.each do |id, source_id, destination_id|
        visible_ids << id if searchable.include?(source_id) && searchable.include?(destination_id)
      end
      return visible_ids.first(wanted) if visible_ids.size >= wanted
    end
    rows.size < SCAN_LIMIT ? visible_ids : nil
  end

  # Matches where both clients are searchable to the current user. Pass the candidate matches to
  # limit the searchable lookup to the clients they involve. A CTE builds the searchable set once
  # instead of re-running the subquery per row (Postgres materializes it because it is referenced twice).
  # Users whose search is unrestricted skip the filter.
  private def client_match_scope(candidates = nil)
    matches = candidates || GrdaWarehouse::ClientMatch.all
    return matches if current_user.legacy_can_search_across_all_clients?

    client_ids = candidates&.pluck(:source_client_id, :destination_client_id)&.flatten&.uniq
    # An empty client_ids means no id filter (the user's search limit still applies), so
    # [0] keeps the candidate set empty when there are no candidate matches.
    client_ids = [0] if candidates && client_ids.empty?
    searchable_ids = GrdaWarehouse::Hud::Client.searchable_to(current_user, client_ids: client_ids).select(:id)
    searchable = Arel::Table.new(:searchable_clients)
    matches.with(searchable_clients: searchable_ids).
      where(GrdaWarehouse::ClientMatch.arel_table[:source_client_id].in(searchable.project(searchable[:id]))).
      where(GrdaWarehouse::ClientMatch.arel_table[:destination_client_id].in(searchable.project(searchable[:id])))
  end
end
