###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients
  class HistoryController < ApplicationController
    include ClientPathGenerator

    before_action :require_can_see_this_client_demographics!
    before_action :set_client
    before_action :check_release, unless: :can_view_clients?
    before_action :set_dates, only: [:show]
    before_action :set_pdf_dates, only: :pdf
    skip_before_action :require_can_see_this_client_demographics!, only: [:pdf]
    skip_before_action :authenticate_user!, only: [:pdf]
    before_action :require_client_needing_processing!, only: [:pdf]
    after_action :log_client

    def show
      @ordered_dates = @dates.keys.sort
      @start = @ordered_dates.first || Date.current
      @end = @ordered_dates.last || Date.current
      @date_range = (@start.beginning_of_month..@end.end_of_month)
      @months = @date_range.map do |date|
        [date.year, date.month]
      end.uniq
    end

    def queue
      @years = (params[:pdf].try(:[], :years) || 3).to_i
      @client.update(generate_manual_history_pdf: true)
      job = Delayed::Job.enqueue ServiceHistory::ChronicVerificationJob.new(
        client_id: @client.id,
        years: @years,
      ), queue: :default_priority
      flash[:notice] = "Homeless Verification PDF queued for generation.  The PDF will be available for download under the Files tab within a few minutes."
      redirect_to action: :show
    end

    def pdf
      # force some consistency.  We may be generating this for a client we haven't seen in over a year
      # the processed data only gets cached for those with recent enrollments
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [@client.id])
      show
      @user = User.setup_system_user()
      # Limit to Residential Homeless programs
      @dates = @dates.map do |date, data|
        [
          date,
          data.select{|en| GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS.include?(en[:project_type])}
        ]
      end.to_h
      @organization_counts = @dates.values.flatten.group_by{|en| HUD.project_type en[:organization_name]}.map{|org, ens| [org, ens.count]}.to_h
      @project_type_counts = @dates.values.flatten.group_by{|en| HUD.project_type en[:project_type]}.map{|project_type, ens| [project_type, ens.count]}.to_h
      file_name = "service_history.pdf"

      # DEBUGGING
      # render pdf: file_name, template: "window/clients/history/pdf", layout: false, encoding: "UTF-8", page_size: 'Letter'
      # return
      # END DEBUGGING

      pdf = render_to_string pdf: file_name, template: "window/clients/history/pdf", layout: false, encoding: "UTF-8", page_size: 'Letter'
      @file = GrdaWarehouse::ClientFile.new
      begin
        tmp_path = Rails.root.join('tmp', "service_history_pdf_#{@client.id}.pdf")
        file = File.open(tmp_path, 'wb')
        file.write(pdf)
        @file.file = file
        @file.content = @file.file.read
      ensure
        tmp_path.unlink()
      end

      @file.client_id = @client.id
      @file.user_id = User.find_by(email: 'noreply@greenriver.com').id
      @file.note = "Auto Generated for prior #{@years} years"
      @file.name = file_name
      @file.visible_in_window = true
      @file.effective_date = Date.current
      @file.tag_list.add(['Homeless Verification'])
      @file.save!
      # allow for multiple mechanisms to trigger this without getting in the way
      # of CAS triggering it.
      if @client.generate_manual_history_pdf
        @client.update(generate_manual_history_pdf: false)
      else
        @client.update(generate_history_pdf: false)
      end
      head :ok
    end

    def set_dates
      @dates = {}
      enrollment_scope.
        includes(:service_history_services, :organization).
        each do |enrollment|
          project_type = enrollment.send(enrollment.class.project_type_column)
          project_name = name_for_project(enrollment.project_name)
          @dates[enrollment.date] ||= []
          record = {
            date: enrollment.date,
            record_type: enrollment.record_type,
            project_type: project_type,
            project_name: project_name,
            organization_name: nil,
          }
          unless project_name == GrdaWarehouse::Hud::Project.confidential_project_name
            record[:organization_name] = enrollment.organization.OrganizationName
          end
          @dates[enrollment.date] << record
          enrollment.service_history_services.each do |service|
            @dates[service.date] ||= []
            @dates[service.date] << {
              date: service.date,
              record_type: service.record_type,
              project_type: project_type,
              project_name: project_name,
              organization_name: nil,
            }
          end
        end
    end

    def set_pdf_dates
      @dates = {}
      @years = (params[:years] || 3).to_i
      enrollment_scope.homeless.enrollment_open_in_prior_years(years: @years).
        where(record_type: [:entry, :exit]).
        preload(:service_history_services, :organization).
        each do |enrollment|
          project_type = enrollment.send(enrollment.class.project_type_column)
          project_name = name_for_project(enrollment.project_name)
          @dates[enrollment.date] ||= []
          record = {
            record_type: enrollment.record_type,
            project_type: project_type,
            project_name: project_name,
            organization_name: nil,
            entry_date: enrollment.first_date_in_program,
            exit_date: enrollment.last_date_in_program,
          }
          if project_name == GrdaWarehouse::Hud::Project.confidential_project_name
            record[:organization_name] = 'Confidential'
          else
            record[:organization_name] = enrollment.organization.OrganizationName
          end
          @dates[enrollment.date] << record
          enrollment.service_history_services.service_in_prior_years(years: @years).
          each do |service|
            @dates[service.date] ||= []
            record = {
              record_type: service.record_type,
              project_type: project_type,
              project_name: project_name,
              organization_name: nil,
              exit_date: enrollment.last_date_in_program,
            }
            if project_name == GrdaWarehouse::Hud::Project.confidential_project_name
              record[:organization_name] = 'Confidential'
            else
              record[:organization_name] = enrollment.organization.OrganizationName
            end
            @dates[service.date] << record
          end
        end
    end

    def set_client
      not_authorized! and return unless current_user.present?

      # Do we have this client?
      # If not, attempt to redirect to the most recent version
      # If there's not merge path, just force an active record not found
      if client_scope.where(id: params[:client_id].to_i).exists?
        @client = client_scope.find(params[:client_id].to_i)
      else
        client_id = GrdaWarehouse::ClientMergeHistory.new.current_destination params[:client_id].to_i
        if client_id
          redirect_to controller: controller_name, action: action_name, client_id: client_id
          # client_scope.find(client_id)
        else
          @client = client_scope.find(params[:client_id].to_i)
        end
      end
    end
    alias_method :set_client_from_client_id, :set_client

    def require_client_needing_processing!
      if @client.generate_history_pdf || @client.generate_manual_history_pdf
        return true
      end
      not_authorized!
    end

    private def client_source
      GrdaWarehouse::Hud::Client
    end

    private def name_for_project project_name
      if can_view_projects?
        project_name
      else
        GrdaWarehouse::Hud::Project.confidentialize(name: project_name)
      end
    end

    private def enrollment_scope
      @client.service_history_enrollments.visible_in_window_to(current_user)
    end

    private def client_scope
      client_source.destination.
        joins(source_clients: :data_source).
        merge(GrdaWarehouse::DataSource.visible_in_window_to(current_user))
    end

    private def title_for_show
      "#{@client.name} - Service History"
    end
  end
end
