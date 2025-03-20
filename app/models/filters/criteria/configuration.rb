# frozen_string_literal: true

# abstraction that encapsulates filter behavior previously managed by instance variables and params

class Filters::Criteria::Configuration
  attr_reader :age_ranges, :all_project_types, :include_date_range, :chronic_at_entry, :join_clients_method, :project_types, :report_scope_source

  def initialize(all_project_types: nil, include_date_range: true, chronic_at_entry: true, join_clients_method: :client, project_types: nil, report_scope_source: GrdaWarehouse::ServiceHistoryEnrollment.entry)
    @all_project_types = all_project_types
    @include_date_range = include_date_range
    @chronic_at_entry = chronic_at_entry
    @join_clients_method = join_clients_method
    @project_types = project_types
    @report_scope_source = report_scope_source
  end
end
