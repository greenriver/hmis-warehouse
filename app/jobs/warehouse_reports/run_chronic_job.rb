module WarehouseReports
  class RunChronicJob < ActiveJob::Base
    include ArelHelper
    include Chronic

    queue_as :chronic_report

    attr_accessor :params

    def perform report_params
      self.params = report_params
      load_filter
      report = GrdaWarehouse::WarehouseReports::ChronicReport.new
      report.started_at = DateTime.now
      report.parameters = params.slice(:filter).merge(date: @filter.date)
      load_filter

      @clients = @clients.includes(:chronics).
        preload(source_clients: :data_source).
        merge(GrdaWarehouse::Chronic.on_date(date: @filter.date)).
        order( @order )
      @client_ids = @clients.map { |client| client.id }

      @so_clients = service_history_source.entry.so.ongoing(on_date: @filter.date).distinct.pluck(:client_id)

      most_recent_services = service_history_source.service
        .where(client_id: @client_ids, project_type: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
        .group(:client_id)
        .pluck(:client_id, nf('MAX', [sh_t[:date]]).to_sql)
        .to_h

      data = @clients.map do |client|
        chronic = client.chronics.first
        data_sources = client.source_clients.map do |m| 
            m.data_source.short_name
        end.uniq.join(', ')
        source_disabilities = client.source_disabilities.select do |m| ![0,8,9,99].include? m.DisabilityResponse
        end.map do |m| 
          m.disability_type_text
        end.uniq.join('<br />').html_safe

        source_clients = client.source_clients.map do |sc|
          sc.attributes.merge(data_source_short_name: sc.data_source.short_name)
        end

        client.attributes.merge(
          chronic: chronic,
          chronic_project_names: chronic.project_names,
          age: client.age,
          veteran: client.veteran?,
          so_clients: @so_clients,
          data_sources: data_sources,
          source_clients: source_clients,
          source_disabilities: source_disabilities,
          data_source: client.data_source,
          most_recent_service: most_recent_services[client.id]
        )
      end
      report.client_count = @clients.size
      report.finished_at = DateTime.now
      report.data = data.to_json
      report.save

      NotifyUser.chronic_report_finished(report_params[:current_user_id], report.id).deliver_later
    end

    def log msg, underline: false
      return unless Rails.env.development?
      Rails.logger.info msg
      Rails.logger.info "="*msg.length if underline
    end
    
    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

  end
end