###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WeatherController < ApplicationController
  before_action :require_can_view_clients!

  # curl -H "token:WjCpqkWTiuxShTcPopqjOlhINzdBeOfG" https://www.ncdc.noaa.gov/cdo-web/api/v2/locations/ZIP:02108?datasetid=GHCND&startdate=2010-10-01&enddate=2010-10-01
  def index
    @date = weather_params['date']
    @weather = Weather::NoaaService.new.weather_on_date(@date.to_date) if @date.present?
    render json: @weather
  end

  private def weather_params
    params.permit(:date)
  end
end
