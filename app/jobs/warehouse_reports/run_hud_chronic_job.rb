###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class RunHudChronicJob < BaseJob
    include ArelHelper
    include HudChronic

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    attr_accessor :params

    def perform(report_params)
      # load_filter expects params from the controller, so we store them in an attribute, and add permit to it
      report_params.define_singleton_method(:deep_slice) do |*args|
        result = {}
        args.each do |arg|
          if arg.is_a?(Hash)
            arg.each do |key, value|
              hash = {}
              if value.is_a?(Array)
                value.each do |elem|
                  hash[elem] = self[key][elem]
                end
              elsif value.is_a?(Hash)
                raise 'Unsupported nesting'
              else
                hash[value] = self[key][value]
              end
              result[key] = hash
            end
          else
            result[arg] = self[arg]
          end
        end
        result
      end
      report_params.define_singleton_method(:permit) { |*args| deep_slice(*args) }
      self.params = report_params

      load_filter
      report = GrdaWarehouse::WarehouseReports::HudChronicReport.new
      report.started_at = DateTime.now
      report.parameters = params.slice(:filter).merge(date: @filter.date)
      load_filter

      @clients = @clients.includes(:hud_chronics).
        preload(source_clients: :data_source).
        merge(GrdaWarehouse::HudChronic.on_date(date: @filter.date)).
        order(@order)
      @client_ids = @clients.map(&:id)

      @so_clients = service_history_source.entry.so.ongoing(on_date: @filter.date).distinct.pluck(:client_id)

      most_recent_services = GrdaWarehouse::ServiceHistoryService.service.
        where(client_id: @client_ids, project_type: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES).
        group(:client_id).
        pluck(:client_id, nf('MAX', [shs_t[:date]]).to_sql).
        to_h

      data = @clients.map do |client|
        hud_chronic = client.hud_chronics.first
        data_sources = client.source_clients.map do |m|
          m.data_source&.short_name
        end.compact.uniq.join(', ')
        source_disabilities = client.source_disabilities.reject do |m|
          [0, 8, 9, 99].include? m.DisabilityResponse
        end.map(&:disability_type_text).uniq.join('<br />').html_safe

        source_clients = client.source_clients.map do |sc|
          next sc.attributes unless sc.data_source

          sc.attributes.merge(data_source_short_name: sc.data_source.short_name)
        end

        client.attributes.merge(
          hud_chronic: hud_chronic,
          chronic_project_names: hud_chronic.project_names,
          age: client.age,
          veteran: client.veteran?,
          so_clients: @so_clients,
          data_sources: data_sources,
          source_clients: source_clients,
          source_disabilities: source_disabilities,
          data_source: client.data_source,
          most_recent_service: most_recent_services[client.id],
        )
      end
      report.client_count = @clients.size
      report.finished_at = DateTime.now
      report.data = data
      report.save

      NotifyUser.hud_chronic_report_finished(report_params[:current_user_id], report.id).deliver_later
    end

    def log(msg, underline: false)
      return unless Rails.env.development?

      Rails.logger.info msg
      Rails.logger.info '=' * msg.length if underline
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
