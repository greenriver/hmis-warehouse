###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Efind
  extend ActiveSupport::Concern
  included do
    def self.efind(raw)
      find(raw) if raw.is_a?(Integer)
      decoded = ProtectedId::Encoder.decode(raw)
      find(decoded)
    end
  end
end
