###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Cohorts
  class AclAccessAuditsController < ApplicationController
    include CohortAccessAuditing

    private

    def audit_service_class
      Audit::CohortAccess::Acl
    end
  end
end
