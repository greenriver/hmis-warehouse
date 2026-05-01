###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ClientProxy supports flexibility and deduplication of clients on CE referral waitlists.
# Hmis::Ce::Match::Candidate refers to this class instead of directly to a client record.
# - Proxy class allows more flexibility to point at other records (such as non-HMIS VSP clients)
# - Using destination client ensures clients are deduplicated on waitlists, even if they are duplicated in source client records.
# - Destination client also allows use of full client data to determine eligibility (e.g., open enrollments across deduplicated records).
module Hmis::Ce
  class ClientProxy < GrdaWarehouseBase
    # Bulk-managed, does not log to paper_trail
    # Soft-deleted to avoid losing historical CE match data
    acts_as_paranoid

    # For now, this is the GrdaWarehouse::Hud::Client representing the *destination* client.
    # In the future, we will add more client types (e.g. VSP)
    belongs_to :client, polymorphic: true, optional: false
    belongs_to :destination_client, -> { where(ClientProxy.arel_table[:client_type].eq('GrdaWarehouse::Hud::Client')) }, foreign_key: 'client_id', class_name: 'GrdaWarehouse::Hud::Client', optional: true
    has_many :ce_match_candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :client_proxy_id, dependent: :destroy
    # avoid dependent destroy/delete to preserve historical data
    has_many :ce_match_candidate_events, class_name: 'Hmis::Ce::Match::CandidateEvent', foreign_key: :client_proxy_id

    validates :client_id, presence: true, uniqueness: { scope: [:client_type] }
    validate :client_is_destination

    scope :for_warehouse_clients, -> { where(client_type: GrdaWarehouse::Hud::Client.sti_name) }

    scope :matching_search_term, ->(search_term) do
      search_term = search_term.strip

      cp_t = Hmis::Ce::ClientProxy.arel_table
      c_t = GrdaWarehouse::Hud::Client.arel_table
      query = cp_t.join(c_t).
        on(cp_t[:client_id].eq(c_t[:id]).
        and(cp_t[:client_type].eq('GrdaWarehouse::Hud::Client'))).
        join_sources

      joins(query).merge(GrdaWarehouse::Hud::Client.text_search(search_term, sorted: false))
    end

    scope :eligible_for_project_type, ->(project_types) do
      joins(ce_match_candidates: { candidate_pool: { unit_groups: :project, opportunities: :project } }).
        where(Hmis::Hud::Project.arel_table[:project_type].in(Array.wrap(project_types)))
    end

    # Narrow CE client proxies to those whose latest assessments have a CustomDataElement value
    # matching any of the given filter values (same semantics as `CdeFieldMap#client_query`).
    #
    # Example: `scope.matching_dynamic_cde_filter('custom_assessment.language_preference', ['English'])`
    scope :matching_dynamic_cde_filter, ->(custom_assessment_field, filter_values) do
      filter_values = Array.wrap(filter_values).map(&:to_s).reject(&:blank?).uniq
      if filter_values.empty?
        all
      else
        sql, binds = sql_cde_value_exists_for_ce_client_proxy(custom_assessment_field, filter_values)
        where([sql, *binds])
      end
    end

    # Returns a correlated `EXISTS` SQL fragment (and bind values) for `scope.where([sql, *binds])`.
    # The EXISTS is tied to each row's `ce_client_proxies.client_id` (destination warehouse client id):
    # a proxy matches when that client's latest assessment for the CDE's form has a CDE value in
    # `filter_values`, using `Hmis::DestinationClientLatestAssessment` the same way as
    # `Hmis::Ce::Match::Expression::CdeFieldMap#client_query`.
    #
    # Added to support dynamic filtering on CE waitlists based on CDE values, using
    # `cde.*` keys from `Hmis::Filter::CeClientFilter` / table configuration.
    #
    # Values are compared as `column::text IN (...)` so HUD/UI string filter values behave predictably.
    # `filter_values` must be non-empty after stripping blanks; callers with nothing to match should skip.
    #
    # @param custom_assessment_field [String] argument to `CdeFieldMap#parse_entity_type`
    #   (e.g. `'custom_assessment.primary_language'`, the portion of a `cde.*` expression key after `cde.`)
    # @param filter_values [Array<String,#to_s>] values to match (e.g. ['English', 'Spanish'])
    # @return [Array(String, Array)] SQL string and bind arguments for `scope.where([sql, *binds])`
    def self.sql_cde_value_exists_for_ce_client_proxy(custom_assessment_field, filter_values)
      raise ArgumentError, 'filter_values must be non-empty' if filter_values.empty?

      conn = ActiveRecord::Base.connection
      dcla = conn.quote_table_name(Hmis::DestinationClientLatestAssessment.table_name)
      ca = conn.quote_table_name(Hmis::Hud::CustomAssessment.table_name)
      cde_tbl = conn.quote_table_name(Hmis::Hud::CustomDataElement.table_name)
      cde_alias = 'cde'
      proxy = conn.quote_table_name(Hmis::Ce::ClientProxy.table_name)

      # Get the CustomDataElementDefinition and determine the value column name (e.g. value_string)
      cded = Hmis::Ce::Match::Expression::CdeFieldMap.new.parse_entity_type(custom_assessment_field)
      value_col = conn.quote_column_name(cded.cde_arel_field.name.to_s)

      # Create predicate for matching CustomDataElement values
      # For example: (cde.value_string)::text IN (?, ?, ?)
      placeholders = filter_values.map { '?' }.join(', ')
      value_predicate = "(#{cde_alias}.#{value_col})::text IN (#{placeholders})"

      sql = <<~SQL
        EXISTS (
          SELECT 1
          FROM #{dcla} dcla
          INNER JOIN #{ca} ca ON ca.id = dcla.custom_assessment_id AND ca."DateDeleted" IS NULL
          INNER JOIN #{cde_tbl} #{cde_alias} ON #{cde_alias}.owner_type = ?
            AND #{cde_alias}.owner_id = ca.id
            AND #{cde_alias}."DateDeleted" IS NULL
            AND #{cde_alias}.data_element_definition_id = ?
          WHERE dcla.destination_client_id = #{proxy}.client_id
            AND dcla.form_identifier = ?
            AND (#{value_predicate})
        )
      SQL

      # Values to bind to the '?' placeholders in the SQL fragment
      binds = [Hmis::Hud::CustomAssessment.name, cded.id, cded.form_definition_identifier] + filter_values
      [sql.squish, binds]
    end

    def self.apply_filters(input)
      Hmis::Filter::CeClientFilter.new(input).filter_scope(current_scope)
    end

    def client_is_destination
      errors.add :client, 'must be destination client' unless GrdaWarehouse::DataSource.destination_data_source_ids.include?(client.data_source_id)
    end
  end
end
