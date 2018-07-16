module Window::Clients
  class HistoryController < ApplicationController
    include WindowClientPathGenerator

    before_action :require_can_see_this_client_demographics!
    before_action :set_client, :check_release
    before_action :set_dates, only: [:show]
    before_action :set_pdf_dates, only: :pdf
    skip_before_action :require_can_see_this_client_demographics!, only: [:pdf]
    skip_before_action :authenticate_user!, only: [:pdf]
    before_action :require_client_needing_processing!, only: [:pdf]

    def show
      @ordered_dates = @dates.keys.sort
      @start = @ordered_dates.first || Date.today
      @end = @ordered_dates.last || Date.today
      @date_range = (@start.beginning_of_month..@end.end_of_month)
      @months = @date_range.map do |date|
        [date.year, date.month]
      end.uniq
    end

    def pdf
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
      # or from your controller, using views & templates and all wicked_pdf options as normal

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
      @file.note = 'Auto Generated'
      @file.name = file_name
      @file.visible_in_window = true
      @file.effective_date = Date.today
      @file.tag_list.add(['Homeless Verification'])
      @file.save!
      @client.update(generate_history_pdf: false)
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
      enrollment_scope.homeless.enrollments_open_in_last_three_years.
        includes(:service_history_services, :organization).
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
          enrollment.service_history_services.service_in_last_three_years.
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

    def name_for_project project_name
      GrdaWarehouse::Hud::Project.confidentialize(name: project_name)
    end

    def enrollment_scope
      @client.service_history_enrollments.visible_in_window_to(current_user)
    end

    def set_client
      @client = client_scope.find(params[:client_id].to_i)
    end
    alias_method :set_client_from_client_id, :set_client

    def require_client_needing_processing!
      if @client.generate_history_pdf
        return true
      end
      not_authorized!
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def client_scope
      client_source.destination.
        joins(source_clients: :data_source).
        merge(GrdaWarehouse::DataSource.visible_in_window_to(current_user))
    end
  end
end
