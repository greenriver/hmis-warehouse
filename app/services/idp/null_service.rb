###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Stub. The no-op Idp::Service used when no connector is known; the real
  # implementation lands in L1.4 (idp-l1-service-layer). Present here only so
  # IdpSupport's references resolve to a defined constant.
  class NullService
    def supports_user_management?
      raise NotImplementedError, 'Idp::NullService is a stub; implemented in L1.4 (service-layer)'
    end

    def supports_profile_updates?
      raise NotImplementedError, 'Idp::NullService is a stub; implemented in L1.4 (service-layer)'
    end
  end
end
