# frozen_string_literal: true

# Describes the eligibility requirements and prioritization for a client.

module Hmis::Ce::Match
  class CandidatePool < GrdaWarehouseBase
    self.table_name = 'ce_match_candidate_pools'
    has_many :candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :candidate_pool_id, dependent: :destroy
    has_many :opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception

    def relevant_form_definition_identifiers
      expressions = [requirement_expression, priority_expression]

      cded_keys = expressions.map do |expression|
        expression.scan(/cde\.custom_assessment\.([a-zA-Z0-9_-]+)/).flatten
      end.flatten

      Hmis::Hud::CustomDataElementDefinition.where(key: cded_keys).pluck(:form_definition_identifier).uniq
    end
  end
end
