###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::ClientNotes
  class CohortNote < Base
    def self.type_name
      'Cohort Note'
    end

    def destroyable_by(user)
      # Cohort notes may appear on multiple cohorts, so check the cohorts the client is on
      # and check the column in the controller.
      return false unless client

      client.cohort_clients.preload(:cohort).any? do |cohort_client|
        cohort_client.cohort.present? && user.policy_for(cohort_client.cohort).can_edit_clients?
      end
    end
  end
end
