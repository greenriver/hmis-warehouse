###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Stub. Resolves a connector_id to an Idp::Service instance; the real
  # implementation lands in L1.4 (idp-l1-service-layer). Present here only so
  # IdpSupport's references resolve to a defined constant. Contract for L1.4:
  # for_connector must never raise for an unknown connector (return a
  # NullService-equivalent instead).
  class ServiceFactory
    def self.for_connector(_connector_id)
      raise NotImplementedError, 'Idp::ServiceFactory is a stub; implemented in L1.4 (service-layer)'
    end
  end
end
