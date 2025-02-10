#  clean abstraction that encapsulates filter behavior previously managed by instance variables

class Filters::Criteria::Configuration
  attr_reader :age_ranges, :all_project_types, :multi_coc_code_filter, :include_date_range, :chronic_at_entry, :join_clients_method, :project_types

  def initialize(all_project_types: nil, multi_coc_code_filter: true, include_date_range: true, chronic_at_entry: true, join_clients_method: :client, project_types: nil)
    @all_project_types = all_project_types
    @multi_coc_code_filter = multi_coc_code_filter
    @include_date_range = include_date_range
    @chronic_at_entry = chronic_at_entry
    @join_clients_method = join_clients_method
    @project_types = project_types
  end
end
