module Bo
  class ClientIdLookp

    def self.fetch_client_modifications
      wsdl_url = ENV['BO_WSDL_URL']
      params = {
        wsdl: 1,
        cuid: ENV['BO_HMIS_PARTICIPANTS'],
      }
      url = wsdl_url + params.to_query

      client = Savon.client do |globals|
        globals.wsdl(url)
      end

      client.operations
      # => [:run_query_as_a_service, :run_query_as_a_service_ex, :values_of_site_name]

      response = client.call(:run_query_as_a_service, message: { login: ENV['BO_USER_1'], password: ENV['BO_PASS_1'], Cms: ENV['BO_SERVER_1']});
      response.body
    end


    # extend Savon::Model

    # client wsdl: ENV['BO_CLIENT_LOOKUP_WSDL_1']

    # global basic_auth,


    # client = Savon.client do |globals|
    #   # globals.endpoint(ENV['BO_URL_1'])
    #   globals.wsdl(ENV['BO_CLIENT_LOOKUP_WSDL_1'])
    # end

    # #######
    # wsdl_url = ENV['BO_WSDL_URL']

    # # list sites
    # params = {
    #   wsdl: 1,
    #   cuid: ENV['BO_SITE_LIST'],
    # }
    # url = wsdl_url + params.to_query

    # client = Savon.client do |globals|
    #   # globals.endpoint(ENV['BO_URL_1'])
    #   globals.wsdl(url)
    # end

    # client.operations
    # # => [:run_query_as_a_service, :run_query_as_a_service_ex, :values_of_site_name]

    # response = client.call(:run_query_as_a_service, message: { login: ENV['BO_USER_1'], password: ENV['BO_PASS_1'], Cms: ENV['BO_SERVER_1']})

    # response = client.call(:values_of_site_name, message: { login: ENV['BO_USER_1'], password: ENV['BO_PASS_1'], Cms: ENV['BO_SERVER_1'] })
  end
end

# Connect and fetch touch point modification dates
wsdl_url = ENV['BO_WSDL_URL']
params = {
  wsdl: 1,
  # cuid: ENV['BO_HMIS_PARTICIPANTS'],
  cuid: ENV['BO_HMIS_PARTICIPANTS_ADVANCED'],
}
url = wsdl_url + params.to_query

client = Savon.client do |globals|
  # globals.endpoint(ENV['BO_URL_1'])
  globals.wsdl(url)
end

client.operations
# => [:run_query_as_a_service, :run_query_as_a_service_ex, :values_of_site_name]

response = client.call(:run_query_as_a_service_ex, message: { login: ENV['BO_USER_1'], password: ENV['BO_PASS_1'], Cms: ENV['BO_SERVER_1'], Date: '2019-04-01'});
response.body