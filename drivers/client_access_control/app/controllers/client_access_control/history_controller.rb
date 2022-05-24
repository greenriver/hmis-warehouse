###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
    before_action :set_dates, only: [:show]
    after_action :log_client

    def show
      @ordered_dates = @dates.keys.sort
      @start = @ordered_dates.first || Date.current
      @end = @ordered_dates.last || Date.current
      @date_range = (@start.beginning_of_month..@end.end_of_month)
      @months = @date_range.map do |date|
        [date.year, date.month]
      end.
        uniq
    end

    def queue
      @years = (params[:pdf].try(:[], :years) || 3).to_i
      @client.update(generate_manual_history_pdf: true)
      ServiceHistory::ChronicVerificationJob.perform_later(
        client_id: @client.id,
        years: @years,
      )
      flash[:notice] = 'Homeless Verification PDF queued for generation.  The PDF will be available for download under the Files tab within a few minutes.'
      redirect_to action: :show
    end

    def pdf
      @user = User.setup_system_user
      current_user ||= @user # rubocop:disable Lint/UselessAssignment
      @client = ::GrdaWarehouse::Hud::Client.destination.find(params[:client_id].to_i)
      set_pdf_dates

      return not_authorized! unless client_needing_processing?

      # force some consistency.  We may be generating this for a client we haven't seen in over a year
      # the processed data only gets cached for those with recent enrollments
      ::GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [@client.id])
      show

      # Limit to Residential Homeless programs
      @dates = @dates.transform_values do |data|
        data.select { |en| ::GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS.include?(en[:project_type]) }
      end
      @organization_counts = @dates.values.flatten.group_by { |en| HUD.project_type en[:organization_name] }.transform_values(&:count)
      @project_type_counts = @dates.values.flatten.group_by { |en| HUD.project_type en[:project_type] }.transform_values(&:count)
      file_name = 'service_history.pdf'

      template_file = 'client_access_control/history/pdf'
      layout = false
      pdf = nil
      html = PdfGenerator.html(
        controller: ClientAccessControl::HistoryController,
        template: template_file,
        layout: layout,
        user: @user,
        assigns: {
          organization_counts: @organization_counts,
          project_type_counts: @project_type_counts,
          user: @user,
          dates: @dates,
          client: @client,
          ordered_dates: @dates.keys.sort,
        },
      )
      PdfGenerator.new.perform(
        html: html,
        file_name: file_name,
      ) do |io|
        pdf = io.read
      end

      @file = ::GrdaWarehouse::ClientFile.new
      begin
        tmp_path = Rails.root.join('tmp', "service_history_pdf_#{@client.id}.pdf")
        file = File.open(tmp_path, 'wb')
        file.write(pdf)
        @file.file = file
        @file.content = @file.file.read
      ensure
        tmp_path.unlink
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
          project_name = enrollment.project&.name(include_confidential_names: current_user.can_view_confidential_enrollment_details?)
          @dates[enrollment.date] ||= []
          record = {
            date: enrollment.date,
            record_type: enrollment.record_type,
            project_type: project_type,
            project_name: project_name,
            organization_name: nil,
          }
          record[:organization_name] = enrollment.organization.OrganizationName unless project_name == ::GrdaWarehouse::Hud::Project.confidential_project_name
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
      # TODO: this is a temporary permission until we determine what the permission should actually be
      # this maps back to who can setup the import file
      return unless current_user&.can_manage_config?

      @client.generic_services.find_each do |service|
        @dates[service.date] ||= []
        @dates[service.date] << {
          date: service.date,
          record_type: 'service',
          project_type: 7, # HUD project_types "Other"
          project_name: service.category, # this is more generic than service.name
          organization_name: nil,
        }
      end
    end

    def set_pdf_dates
      @dates = {}
      @years = (params[:years] || 3).to_i
      pdf_enrollment_scope.homeless.enrollment_open_in_prior_years(years: @years).
        where(record_type: [:entry, :exit]).
        preload(:service_history_services, :organization, :project).
        each do |enrollment|
          project_type = enrollment.send(enrollment.class.project_type_column)
          project_name = enrollment.project&.name(include_confidential_names: current_user.can_view_confidential_enrollment_details?)
          @dates[enrollment.date] ||= []
          record = {
            record_type: enrollment.record_type,
            project_type: project_type,
            project_name: project_name,
            organization_name: nil,
            entry_date: enrollment.first_date_in_program,
            exit_date: enrollment.last_date_in_program,
          }
          if project_name == ::GrdaWarehouse::Hud::Project.confidential_project_name
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
            if project_name == ::GrdaWarehouse::Hud::Project.confidential_project_name
              record[:organization_name] = 'Confidential'
            else
              record[:organization_name] = enrollment.organization.OrganizationName
            end
            @dates[service.date] << record
          end
        end
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

    def client_needing_processing?
      return true if @client.generate_history_pdf || @client.generate_manual_history_pdf

      false
    end

    private def client_source
      ::GrdaWarehouse::Hud::Client
    end

    private def enrollment_scope
      @client.service_history_enrollments.visible_in_window_to(current_user)
    end

    # Because the PDF is generated by the system user, we need to only include dates that are "visible in the window"
    private def pdf_enrollment_scope
      @client.service_history_enrollments.joins(:data_source).merge(::GrdaWarehouse::DataSource.where(visible_in_window: true))
    end

    private def title_for_show
      "#{@client.name} - Service History"
    end
  end
end
