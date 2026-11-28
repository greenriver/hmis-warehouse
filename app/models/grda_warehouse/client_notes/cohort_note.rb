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
      # Cohort notes may appear on multiple cohorts, so check every cohort the client is or
      # was on, and check the column in the controller.
      return false unless client

      # Loads onto the client, so the other notes rendered for the same client reuse it.
      ActiveRecord::Associations::Preloader.new(records: [client], associations: { cohort_clients_with_deleted: :cohort }).call
      client.cohort_clients_with_deleted.any? do |cohort_client|
        cohort_client.cohort.present? && user.policy_for(cohort_client.cohort).can_edit_clients?
      end
    end
  end
end
