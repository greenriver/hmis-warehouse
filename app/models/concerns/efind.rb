###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
