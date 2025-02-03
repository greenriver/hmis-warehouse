# sanitized filter input

# responsibilities:
# - constrain input params based on the users permissions
# - normalize inputs (blanks, duplicates, or invalid input)

class Filters::Criteria::Input
  attr_reader :filter, :user, :age_ranges, :all_project_types, :multi_coc_code_filter, :include_date_range, :chronic_at_entry

  def initialize(
    filter:,
    all_project_types: nil,
    multi_coc_code_filter: true,
    include_date_range: true,
    chronic_at_entry: true
  )
    @filter = filter
    @user = filter.user
    @all_project_types = all_project_types
    @multi_coc_code_filter = multi_coc_code_filter
    @include_date_range = include_date_range
    @chronic_at_entry = chronic_at_entry
  end

  delegate(
    :require_service_during_range,
    to: :filter
  )

  def data_source_ids
    filter.data_source_ids.presence if user.report_filter_visible?(:data_source_ids)
  end

  def organization_ids
    filter.organization_ids.presence if user.report_filter_visible?(:organization_ids)
  end

  def project_types
    # TBD document why this is needed
    return nil if all_project_types

    # TBD this also referenced @project_types
    result = filter.project_type_ids.presence || []
    result += HudUtility2024.performance_reporting[:ce] if filter.coordinated_assessment_living_situation_homeless || filter.ce_cls_as_homeless
    result
  end

  def funder_ids
    funder_scope = GrdaWarehouse::Hud::Funder.viewable_by(filter.user, permission: :can_view_assigned_reports)

    filtered = false

    if filter.user.report_filter_visible?(:funder_ids)
      funder_scope = funder_scope.where(Funder: filter.funder_ids)
      filtered = true
    end
    if filter.user.report_filter_visible?(:funder_others)
      funder_scope = funder_scope.where(OtherFunder: filter.funder_others)
      filtered = true
    end
    filtered ? funder_scope.pluck(:funder) : nil
  end

  def coc_codes
    # TBD why do filters differentiate between multi and single coc codes
    if multi_coc_code_filter
      filter.coc_codes.presence
    else
      [@filter.coc_code].compact_blank.presence
    end
  end

  def date_range
    Range.new(filter.start_date, filter.end_date)
  end

  def project_ids
    GrdaWarehouse::Hud::Project
      .viewable_by(user, permission: :can_view_assigned_reports)
      .where(id: filter.project_ids.compact.uniq)
      .order(:id)
      .pluck(:id)
  end

  def project_group_ids
    GrdaWarehouse::ProjectGroup
      .viewable_by(user)
      .where(id: filter.project_group_ids.compact.uniq)
      .order(:id)
      .pluck(:id)
  end

  def age_ranges
    filter.available_age_ranges.values & filter.age_ranges
  end
end
