###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
