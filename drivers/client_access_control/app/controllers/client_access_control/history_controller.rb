###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl
  class HistoryController < ApplicationController
    include ClientPathGenerator
    include ClientDependentControllers

    skip_before_action :authenticate_user!, only: [:pdf]
    before_action :require_can_see_this_client_demographics!, except: [:pdf]
    before_action :set_client, except: [:pdf]
    after_action :log_client

    # Removed from UI to use standard OP date format
    # Leaving here in case we need to restore
    # def format_date_string(date_string)
    #   rslt = ''
    #   if date_string.present?
    #     parts = date_string.split('-').map(&:to_i)
    #     if parts.size == 3
    #       date = Date.new(parts[0], parts[1], parts[2])
    #       rslt = date.strftime('%m/%d/%Y')
    #     end
    #   end
    #   rslt
    # end
    # helper_method :format_date_string

    def show
      max_date = ClientAccessControl::ClientHistoryMonth.new.max_date(@client)
      @month = params[:month]&.to_i || max_date.month
      @year = params[:year]&.to_i || max_date.year
      @filters = {
        project_types: (params[:project_types] || '').split(','),
        projects: (params[:projects] || '').split(','),
        contact_types: (params[:contact_types] || '').split(','),
      }
      @current_date = Date.new(@year, @month, 1)
    end

    def queue
      @years = (params[:pdf].try(:[], :years) || 3).to_i
      @client.update(generate_manual_history_pdf: true)
      ServiceHistory::ChronicVerificationJob.perform_later(
        client_id: @client.id,
        years: @years,
        user_id: current_user.id,
      )
      flash[:notice] = 'Homeless Verification PDF queued for generation.  The PDF will be available for download under the Files tab within a few minutes.'
      redirect_to action: :show
    end

    def pdf
      @client_history = ClientHistory.new(client_id: params[:client_id].to_i, user_id: params[:user_id].to_i, years: params[:years]&.to_i)
      # set @client for when this method is called outside of the controller context.
      @client ||= @client_history.client

      return not_authorized! unless client_needing_processing?(client: @client_history.client)

      # force some consistency.  We may be generating this for a client we haven't seen in over a year
      # the processed data only gets cached for those with recent enrollments
      ::GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [@client_history.client.id])
      show

      @client_history.generate_service_history_pdf
      head :ok
    end

    def set_client
      if current_user.blank? && @user.blank?
        not_authorized!
        return
      end

      # Do we have this client?
      # If not, attempt to redirect to the most recent version
      # If there's not merge path, just force an active record not found
      if destination_searchable_client_scope.where(id: params[:client_id].to_i).exists?
        @client = destination_searchable_client_scope.find(params[:client_id].to_i)
      else
        client_id = ::GrdaWarehouse::ClientMergeHistory.new.current_destination params[:client_id].to_i
        if client_id
          redirect_to controller: controller_name, action: action_name, client_id: client_id
        else
          @client = destination_searchable_client_scope.find(params[:client_id].to_i)
        end
      end
    end

    def client_needing_processing?(client: @client)
      return true if client.generate_history_pdf || client.generate_manual_history_pdf

      false
    end

    private def client_source
      ::GrdaWarehouse::Hud::Client
    end

    private def enrollment_scope
      @client.service_history_enrollments.visible_in_window_to(current_user)
    end

    private def title_for_show
      "#{@client.name} - Service History"
    end
  end
end
