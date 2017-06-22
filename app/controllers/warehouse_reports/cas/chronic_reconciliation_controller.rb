module WarehouseReports::Cas
  class ChronicReconciliationController < ApplicationController
    include ArelHelper
    before_action :require_can_view_reports!

    def index
      @date = if params[:date].present?
        params[:date].to_date
      else
        chronic_source.maximum(:date)
      end
      chronic_ids = chronic_source.where(date: @date).
        where(ch_t[:days_in_last_three_years].gteq(365)).
        pluck(:client_id)
      cas_ids = client_source.cas_active.pluck(:id)
      @missing_in_cas = client_source.joins(:chronics).
        where(chronics: {date: @date}).
        where(id: (chronic_ids - cas_ids)).
        pluck(*client_columns.values).
        map do |row|
          Hash[client_columns.keys.zip(row)]
        end

      @not_on_list = client_source.includes(:chronics).
        where(chronics: {date: @date}).
        where(id: (cas_ids - chronic_ids)).
        pluck(*client_columns.values).
        map do |row|
          Hash[client_columns.keys.zip(row)]
        end
    end

    def client_columns
      {
        client_id: c_t[:id].as('id').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        days: ch_t[:days_in_last_three_years].as('days').to_sql,
        months: ch_t[:months_in_last_three_years].as('months').to_sql,
        trigger: ch_t[:trigger].as('trigger').to_sql,
      }
    end

    def chronic_source
      GrdaWarehouse::Chronic
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def ch_t
      chronic_source.arel_table
    end

    def c_t
      client_source.arel_table
    end
    
  end
end