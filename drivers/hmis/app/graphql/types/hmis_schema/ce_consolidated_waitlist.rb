###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeConsolidatedWaitlist < Types::BaseObject
    skip_activity_log

    field :client_attribute_columns, [Types::HmisSchema::KeyValue], null: false, description: 'Columns available in the consolidated waitlist'
    field :candidates, HmisSchema::CeCandidateConsolidated.page_type, null: false, nodes_count: ->(all_nodes) { all_nodes.count(:id) }

    # filters? TODO figure out filtering on Tay (CDED) and Veteran (CDED)
    # sort? TODO figure out sorting on AHA? nice to have..

    def client_attribute_columns
      # use a flag on CDED to determine this, or have a separate table for configuring consolidated waitlist. column configuration is gonna be a common things
      [
        { key: 'cde.custom_assessment.hna_ce_test_1_prioritization_score', value: 'AHA score' },
        { key: 'cde.custom_assessment.hna_ce_test_1_household_type', value: 'Household type' },
        # Assessment Date-- add to eligibility requirements to be like "it must be present" as a workaround?
        # do we need an expression...to coalesce veteran status questions :cry:- collect onto same CDED.
      ]
    end

    def candidates
      Hmis::Ce::Match::Candidate.all_candidates_by_distinct_unit_group
    end
  end
end
