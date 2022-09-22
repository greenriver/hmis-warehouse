###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteranConfirmation
  class VaCheckHistory < GrdaWarehouseBase
    self.table_name = :va_check_histories

    # Response values
    CONFIRMED = 'confirmed'.freeze
    NOT_CONFIRMED = 'not confirmed'.freeze

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    scope :most_recent_first, -> { order(check_date: :desc) }

    validates :response, presence: true

    def occured_within(days)
      check_date.present? && check_date <= Date.current - days
    end

    def check
      query_result = self.class.check(::GrdaWarehouse::Hud::Client.where(id: client_id))[client_id]
      return unless query_result.present?

      update!(
        response: query_result,
        check_date: Date.current,
      )

      result = query_result == CONFIRMED
      client.update!(va_verified_veteran: client.va_verified_veteran? || result)
      client.adjust_veteran_status
    end

    def self.check(clients)
      return if credentials.nil?

      client_id = 0
      {}.tap do |results|
        last_client_id = clients.pluck(:id).max
        clients.find_in_batches(batch_size: 60) do |batch|
          limiter = RateLimiter.new
          batch.each do |client|
            client_id = client.id
            result = status(client)
            results[client_id] = result if result.present?
          end
          # Avoid rate limiting at the end of the run
          limiter.drain if client_id != last_client_id
        end
      end
    end

    def self.status(client)
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
      http_response = https.request(request)
      json_result = JSON.parse(http_response.read_body)

      json_result['veteran_status']
    rescue Exception
      nil # return no result if there are API problems
    end

    def self.credentials
      @credentials ||= Credential.first
    end
  end
end
