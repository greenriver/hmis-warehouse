###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Cohorts
  # TODO: START_ACL remove this controller when the legacy permission model is removed.
  class LegacyAccessAuditsController < ApplicationController
    include CohortAccessAuditing

    private

    def audit_service_class
      Audit::CohortAccess::Legacy
    end
  end
end
