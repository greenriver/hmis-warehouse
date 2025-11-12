###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health::Soap
  class Payload
    def initialize(payload_id, soap)
      @payload_id = payload_id
      @soap = soap
    end
  end
end
