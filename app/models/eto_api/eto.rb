###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module EtoApi
  class Eto
    def self.site_identifiers
      # somewhat hackish, but figure out which sites we have access to
      ENV.select{|k,v| k.include?('ETO_API_SITE') && v.presence != 'unknown' }.map do |k,v|
        identifier = k.sub('ETO_API_SITE', '')
        data_source_id = ENV.fetch("ETO_API_DATA_SOURCE#{identifier}")
        [ identifier, data_source_id ]
      end
    end
  end
end