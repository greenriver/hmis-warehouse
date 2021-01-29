###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Import::ClientMatching
  CACHE_EXPIRY = if Rails.env.production? then 20.hours else 20.seconds end

  # match name, case insensitive, ignoring all whitespace
  private def name_matches(client)
    return [] unless client.first_name && client.last_name

    key = [client.first_name&.downcase&.gsub(/\s+/, ''), client.last_name&.downcase&.gsub(/\s+/, '')]
    clients_by_name[key]&.map { |c| c[:destination_id] }&.uniq || []
  end

  private def ssn_matches(client)
    return [] unless valid_social?(client.ssn)

    clients_by_ssn[client.ssn]&.map { |c| c[:destination_id] }&.uniq || []
  end

  private def dob_matches(client)
    return [] unless client.dob

    clients_by_dob[client.dob]&.map { |c| c[:destination_id] }&.uniq || []
  end

  def all_clients
    Rails.cache.fetch('all_clients_for_matching', expires_in: CACHE_EXPIRY) do
      GrdaWarehouse::Hud::Client.source.joins(:warehouse_client_source).
        distinct.
        pluck(*client_columns.values).map do |row|
          Hash[client_columns.keys.zip(row)]
        end
    end
  end

  private def clients_by_name
    @clients_by_name ||= all_clients.group_by { |row| [row[:first_name]&.downcase&.gsub(/\s+/, ''), row[:last_name]&.downcase&.gsub(/\s+/, '')] }
  end
  private def clients_by_ssn
    @clients_by_ssn ||= all_clients.group_by { |row| row[:ssn] }
  end

  private def clients_by_dob
    @clients_by_dob ||= all_clients.group_by { |row| row[:dob] }
  end

  private def client_columns
    {
      first_name: :FirstName,
      last_name: :LastName,
      ssn: :SSN,
      dob: :DOB,
      destination_id: wc_t[:destination_id],
    }
  end

  private def valid_social?(ssn)
    ::HUD.valid_social?(ssn)
  end

  private def clean(row)
    clean_row = {}
    self.class.header_map.each do |k, title|
      case k
      when :ssn
        clean_row[k] = row[title]&.gsub('-', '')
      when :dob, :tested_on
        clean_row[k] = row[title]&.to_date
      else
        clean_row[k] = row[title]
      end
    rescue StandardError
      Rails.logger.error "Error processing #{k}"
    end
    clean_row
  end
end
