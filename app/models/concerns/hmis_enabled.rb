###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
