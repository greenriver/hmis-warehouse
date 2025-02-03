###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ExternalHmis::ClientPath
  ##
  # Generates a url path for linking to a client in an external HMIS.  This should be used
  # in conjunction with GrdaWarehouse::ExternalHmisConfiguration to generate URLs suitable for
  # sending a user to the source HMIS.
  #
  # @param configuration [Object] The GrdaWarehouse::ExternalHmisConfiguration object that contains `path_client`
  #   (a string defining the path pattern) and `data_source_id` (for logging purposes).
  # @param client [Object] The client object that contains `personal_id` used for path replacement.
  # @return [String, nil] The constructed external HMIS path or `nil` if the pattern is unknown.
  #
  # Logs an error if the `path_client` pattern is unrecognized.
  #
  def self.external_hmis_path(configuration, client)
    case configuration.path_client
    when 'client/:personal_id:/profile'
      "client/#{client.personal_id}/profile"
    else
      # Silently fail, but drop a note in the log
      Rails.logger.error("Unknown external HMIS replacement pattern: #{configuration.path_client} in data source: #{configuration.data_source_id}")
      return
    end
  end
end
