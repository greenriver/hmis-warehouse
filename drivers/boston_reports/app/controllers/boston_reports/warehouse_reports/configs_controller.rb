module BostonReports::WarehouseReports
  class ConfigsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_config

    def index
    end

    def update
      @config.update(permitted_params)
      respond_with(@config, location: boston_reports_warehouse_reports_configs_path)
    end

    private def set_config
      @config ||= BostonReports::Config.first_or_create(&:default_colors) # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def permitted_params
      params.require(:config).
        permit(*@config.color_fields.flat_map { |d| d[:colors] })
    end
  end
end
