# frozen_string_literal: true

# Hmis::Ce::Match::CandidatePool
# Describes the eligibility requirements and prioritization for a client.

module Hmis::Ce::Match
  class CandidatePool < GrdaWarehouseBase
    self.table_name = 'ce_match_candidate_pools'
    has_one :change_marker, as: :trackable, class_name: 'Hmis::Ce::ChangeMarker', dependent: :destroy
    has_many :candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :candidate_pool_id, dependent: :destroy
    # opportunities may cross-cut projects
    has_many :opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception
    has_many :ce_match_candidate_events, class_name: 'Hmis::Ce::Match::CandidateEvent', foreign_key: :candidate_pool_id, dependent: :destroy

    attr_readonly :requirement_expression, :priority_expression

    # pools for active opportunities
    scope :active, -> {
      active_ids = ::Hmis::Ce::Opportunity.active.pluck(:candidate_pool_id).compact.uniq
      where(id: active_ids)
    }

    scope :orphaned, -> {
      where.not(
        id: ::Hmis::Ce::Opportunity.active.select(:candidate_pool_id).where.not(candidate_pool_id: nil),
      )
    }

    def self.mark_all_dirty
      Hmis::Ce::ChangeMarker.upsert_or_bump_version(
        'Hmis::Ce::Match::CandidatePool',
        trackable_ids: pluck(:id),
      )
    end

    def warehouse_clients
      proxy_scope = Hmis::Ce::ClientProxy.
        joins(:ce_match_candidates).
        where(ce_match_candidates: { candidate_pool_id: id })
      GrdaWarehouse::Hud::Client.joins(:ce_client_proxy).merge(proxy_scope)
    end

    def relevant_form_definition_identifiers
      # Gather relevant expressions for determining priority/eligibility in this candidate pool.
      # These look like: 'current_age > 18' or 'cde.custom_assessment.fieldname = 1'
      expressions = [requirement_expression, priority_expression]

      calculator = Hmis::Ce::Match::Expression::CalculatorFactory.build

      cde_fields = expressions.map do |expression|
        # For each expression, get the list of fields it references. E.g. ['current_age', 'cde.custom_assessment.fieldname']
        fields = calculator.dependencies(expression)

        fields.map do |field|
          # Use the FieldMap to map each field to its type, and skip if it isn't CDE
          field_type, resolved_field = Hmis::Ce::Match::Expression::FieldMap.field_type_for(field)
          next unless field_type == Hmis::Ce::Match::Expression::FieldMap::CDE

          resolved_field
        end.uniq
      end.flatten.compact.uniq

      # Gather all the CDEDs referenced by all CDE fields and return their form definition identifiers
      cdeds = Hmis::Ce::Match::Expression::CdeFieldMap.new.cdeds_for(cde_fields)
      cdeds.pluck(:form_definition_identifier).uniq
    end
  end
end
