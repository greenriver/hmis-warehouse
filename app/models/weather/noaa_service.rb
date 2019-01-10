class Weather::NoaaService
  include NotifierConfig

  def initialize(token=nil)
    api_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/weather.yml")).result)[Rails.env]
    @token = token || api_config['token']
    @endpoint = 'http://www.ncdc.noaa.gov/cdo-web/api/v2/'
  end

  def stations(query_args={})
    get_json 'stations', query_args
  end

  def station(id)
    get_json "stations/#{id}"
  end

  def datatypes(query_args={})
    get_json 'datatypes', query_args
  end

  def data(query_args={})
    get_json 'data', query_args
  end

  def ghcnd(query_args={})
    query_args = {
      datasetid: 'GHCND',
      stationid: 'GHCND:USW00014739',
      units: 'standard',
    }.merge(query_args)

    get_json 'data', query_args
  end

  def weather_on_date(date, query_args={})
    query_args = {
      units: 'standard',
      datasetid: 'GHCND',
      stationid: 'GHCND:USW00014739',
      datatypeid: 'TMIN,TMAX,SNOW,PRCP',
      startdate: date.to_time.strftime('%Y-%m-%d'),
      enddate: date.to_time.strftime('%Y-%m-%d'),
    }.merge(query_args)

    results = get_json('data', query_args)&.[]('results')
    if results.present?
      results.map do |r|
        r.merge(datatypes[r['datatype'].to_sym]).with_indifferent_access
      end
    else
      {}
    end
  end

  private def datatypes
    {
      PRCP: {description: 'Precipitation amount', suffix: 'in'},
      SNOW: {description: 'Snowfall', suffix: 'in'},
      TMAX: {description: 'High temperature', suffix: '°F'},
      TMIN: {description: 'Low temperature', suffix: '°F'},
    }
  end

  private def get_json(path, query_args={})
    url = "#{@endpoint}#{path}?#{query_args.to_param}"
    begin
      JSON::parse(
        RestClient.get(url,
          token: @token
        ).body
      )
    rescue
      setup_notifier('WeatherWarning')
      @notifier.ping("Error contacting the weather API at #{url}") if @send_notifications
    end
  end
end
