###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteranConfirmation
  class Checker
    def check(clients)
      client_id = 0
      {}.tap do |results|
        last_client_id = clients.pluck(:id).max
        clients.find_in_batches(batch_size: 60) do |batch|
          limiter = RateLimiter.new
          batch.each do |client|
            client_id = client.id
            results[client_id] = status(client)
          end
          # Avoid rate limiting at the end of the run
          limiter.drain if client_id != last_client_id
        end
      end
    end

    private def status(client)
      credentials = Credential.first

      query = {
        first_name: client.FirstName,
        last_name: client.LastName,
        ssn: client.SSN,
        birth_date: client.DOB.iso8601,
      }.to_json

      url = URI(credentials.endpoint)
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(credentials.endpoint)
      request['Content-Type'] = 'application/json'
      request['apikey'] = credentials.apikey
      request.body = query
      response = https.request(request)
      result = JSON.parse(response.read_body)

      return result['veteran_status']
    end
  end
end
