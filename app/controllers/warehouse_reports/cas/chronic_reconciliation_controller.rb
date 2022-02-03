###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class ChronicReconciliationController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include SiteChronic

    def index
      @filter = Filter.new(filter_params)

      chronic_ids = client_source.joins(site_chronics_table).
        where(ch_t[:date].eq(@filter.date)).
        where(ch_t[:days_in_last_three_years].gteq(365)).
        has_homeless_service_between_dates(start_date: @filter.homeless_service_after, end_date: @filter.date).
        pluck(:id)

      cas_ids = client_source.cas_active.pluck(:id)
      @missing_in_cas = client_source.joins(site_chronics_table).
        merge(site_chronic_source.on_date(date: @date)).
        where(id: (chronic_ids - cas_ids)).
        order(last_name: :asc, first_name: :asc).
        pluck(*client_columns.values).
        map do |row|
          Hash[client_columns.keys.zip(row)]
        end

      @not_on_list = client_source.
        where(id: (cas_ids - chronic_ids)).
        order(last_name: :asc, first_name: :asc).
        includes(site_chronics_table)
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

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def ch_t
      site_chronic_source.arel_table
    end

    def c_t
      client_source.arel_table
    end

    private def filter_params
      return {} unless params.key? :filter

      params.require(:filter).permit(:date, :homeless_service_after)
    end

    class Filter < ModelForm
      include SiteChronic

      attribute(:date, Date, lazy: true,
                             default: lambda { |filter, _|
                                        begin
                                                                            filter.site_chronic_source.maximum(:date)
                                        rescue StandardError
                                          Date.current
                                                                          end
                                      })
      attribute(:homeless_service_after, Date, lazy: true,
                                               default: lambda { |filter, _|
                                                          begin
                                                                                              filter.site_chronic_source.maximum(:date) - 31.days
                                                          rescue StandardError
                                                            Date.current
                                                                                            end
                                                        })

      def chronic_days
        site_chronic_source.order(date: :desc).distinct.limit(30).pluck(:date)
      end
    end
  end
end
