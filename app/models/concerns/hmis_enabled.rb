###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisEnabled
  extend ActiveSupport::Concern
  included do
    def self.hmis_enabled?
      ENV['ENABLE_HMIS_API'] == 'true' && RailsDrivers.loaded.include?(:hmis)
    end

    def hmis_enabled?
      self.class.hmis_enabled?
    end
  end
end
