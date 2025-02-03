class Filters::Criteria::Resolver
  include Enumerable

  attr_reader :input
  def initialize(...)
    @input = Filters::Criteria::Input.new(...)
  end

  # the criteria set
  def each(&block)
    # TBD user access
    # yield factory(:authorization, user: current_user)

    yield factory(:enrollment_date, date_range: input.date_range)
    yield factory(:service_date, date_range: input.date_range) if input.require_service_during_range
    yield factory(:cocs, coc_codes: input.coc_codes) if input.coc_codes
    yield factory(:project_types, project_types: input.project_types) if input.project_types

    [].tap do |project_filters|
      project_filters << factory(:project_id, project_ids: input.project_ids) if input.project_ids
      project_filters << factory(:project_group_id, project_group_ids: input.project_group_ids) if input.project_group_ids
      yield factory(:disjunction, filters: project_filters) if project_filters.any?
    end

    yield factory(:funders, funder_ids: input.funder_ids) if input.funder_ids
    yield factory(:data_sources, data_source_ids: input.data_source_ids) if input.data_source_ids
    yield factory(:organizations, organization_ids: input.organization_ids) if input.organization_ids
  end

  protected

  FACTORIES = {
    age_range: 'Filters::Criteria::AgeRange',
    days_since_contact: 'Filters::Criteria::DaysSinceLastContact',
    disjunction: 'Filters::Criteria::Disjunction',
    enrollment_date: 'Filters::Criteria::EnrollmentDate',
    service_date: 'Filters::Criteria::ServiceDate',
    project_group_id: 'Filters::Criteria::ProjectGroupId',
    project_id: 'Filters::Criteria::ProjectId',
    project_types: 'Filters::Criteria::ProjectTypes',
    funders: 'Filters::Criteria::Funders',
  }.freeze

  def factory(name, **args)
    class_name = FACTORIES[name]
    raise ArgumentError, "Factory \"#{name}\" is not defined" unless class_name
    class_name.constantize.new(**args)
  end
end
