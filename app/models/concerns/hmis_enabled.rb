###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisEnabled
  extend ActiveSupport::Concern
  included do
    def self.hmis_enabled?
      HmisEnforcement.hmis_enabled?
    end

    def hmis_enabled?
      HmisEnforcement.hmis_enabled?
    end
  end
end
