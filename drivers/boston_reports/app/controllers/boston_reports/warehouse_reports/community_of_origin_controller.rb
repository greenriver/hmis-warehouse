###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module BostonReports::WarehouseReports
  class CommunityOfOriginController < ApplicationController
    def index
      render layout: 'report_with_map'
    end

    def across_the_country_data
      percent_of_clients_data = [
        { name: 'Massachusetts', percent: 0.1 },
        { name: 'Utah', percent: 0.75 },
        { name: 'Idaho', percent: 0.34 },
        { name: 'Vermont', percent: 0.042 },
        { name: 'Connecticut', percent: 0.9 },
        { name: 'Maine', percent: 0.6 },
        { name: 'New Hampshire', percent: 0.25 },
        { name: 'Rhode Island', percent: 0.03 },
      ]
      percent_names = percent_of_clients_data.map { |d| d[:name] }
      GrdaWarehouse::Shape::State.where(name: percent_names).map do |state|
        state.geo_json_properties.merge(percent_of_clients_data.select { |d| d[:name] == state.name }.first)
      end.sort_by { |d| d[:percent] }.reverse
    end
    helper_method :across_the_country_data

    def top_ten_zip_codes_data
      [*1001..2791].map do |zip|
        { zip_code: "0#{zip}", percent: rand(0..0.99) }
      end.sort_by { |d| d[:percent] }.last(10)
    end
    helper_method :top_ten_zip_codes_data
  end
end
