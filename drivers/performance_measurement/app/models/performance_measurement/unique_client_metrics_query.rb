# frozen_string_literal: true

module PerformanceMeasurement
  # UniqueClientMetricsQuery handles the deduplication of client records
  # when calculating aggregated metrics across projects.
  #
  # This query object is used to solve the problem of correctly counting unique clients
  # across multiple client-project relationships when performing metrics calculations.
  # It uses PostgreSQL's DISTINCT ON feature with CTEs to ensure that clients are
  # deduplicated properly before aggregations are performed.
  #
  class UniqueClientMetricsQuery
    attr_reader :clients_scope, :field, :period, :group_by_project

    # Initialize a new deduplication query
    #
    # @param clients_scope [ActiveRecord::Relation] The initial scope of clients
    # @param field [String | Symbol] The question/metric field name
    # @param period [String | Symbol] The reporting period identifier
    # @param project_id [Boolean, Integer, nil] When true, group by all projects; when nil, ignore projects
    def initialize(clients_scope, field, period, group_by_project: false)
      @clients_scope = clients_scope
      @field = field
      @period = period
      @group_by_project = group_by_project
    end

    # Execute the query and return sum(s) of the target column
    #
    # @return [Numeric, Hash] If project_id is blank, returns a single sum.
    #                         Otherwise, returns a hash of sums keyed by project_id.
    def execute_sum
      return with_cte.group(:project_id).sum(column) if group_by_project

      return with_cte.sum(column)
    end

    # Execute the query and return the raw values
    #
    # @return [Array] If project_id is blank, returns an array of values.
    #                 Otherwise, returns an array of [project_id, value] pairs.
    def execute_pluck
      return with_cte.pluck(:project_id, column) if group_by_project

      return with_cte.pluck(column)
    end

    private

    def column
      "#{period}_#{field}"
    end

    def with_cte
      PerformanceMeasurement::Client.unscoped.with(dedup: dedup_query).from('dedup')
    end

    def dedup_query
      base_query = clients_scope.
        joins(:client_projects).
        merge(ClientProject.where(period: period, for_question: field))

      if group_by_project
        # base_query = base_query.merge(ClientProject.where.not(project_id: nil))
        distinct_columns = 'pm_clients.id, pm_client_projects.project_id'
      else
        distinct_columns = 'pm_clients.id'
      end

      base_query.select("DISTINCT ON (#{distinct_columns}) pm_clients.id, #{group_by_project ? 'pm_client_projects.project_id,' : ''} pm_clients.#{column}")
    end
  end
end
