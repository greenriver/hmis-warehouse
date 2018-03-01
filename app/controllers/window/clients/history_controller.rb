module Window::Clients
  class HistoryController < ApplicationController
    include WindowClientPathGenerator
    
    before_action :require_can_see_this_client_demographics!
    before_action :set_client, :check_release
    before_action :set_dates, only: [:show, :pdf]
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
      setup_system_user()
      file_name = "service_history.pdf"
      # or from your controller, using views & templates and all wicked_pdf options as normal
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

    def setup_system_user
      @user = User.find_by(email: 'noreply@greenriver.com')
      return if @user.present?
      @user = User.with_deleted.find_by(email: 'noreply@greenriver.com')
      if @user.present?
        @user.restore
      end
      @user = User.invite!(email: 'noreply@greenriver.com', first_name: 'System', last_name: 'User') do |u|
        u.skip_invitation = true
      end
    end

    def set_dates
      @dates = {}
      enrollment_scope.
        includes(:service_history_services, :organization).
        each do |enrollment|
          project_type = enrollment.project_type
          project_name = name_for_project(enrollment.project_name)
          @dates[enrollment.date] ||= []
          record = {
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
              record_type: service.record_type,
              project_type: project_type,
              project_name: project_name,
              organization_name: nil,
            }
          end
        end
    end

    def name_for_project project_name
      GrdaWarehouse::Hud::Project.confidentialize(name: project_name)
    end

    def enrollment_scope
      @client.service_history_enrollments.visible_in_window
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
        where(data_sources: {visible_in_window: true})
    end
  end
end
