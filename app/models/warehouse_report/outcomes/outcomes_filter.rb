###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::Outcomes::OutcomesFilter < Filters::FilterBase
  # For use in the the view
  attribute :gender, Symbol, default: :all
  attribute :race, Symbol, default: :all
  attribute :veteran_status, Symbol, default: :all

  def set_from_params(filters) # rubocop:disable Naming/AccessorMethodName
    super(filters)

    self.genders = allow(housed_scope.available_genders, filters.dig(:gender).map(&:to_i)) if filters.dig(:gender).present?
    self.gender = genders.first
    self.races = allow(housed_scope.available_races, filters.dig(:races))
    self.race = races.first
    self.age_ranges = allow(housed_scope.available_age_ranges, filters.dig(:age_ranges).map(&:to_sym)) if filters.dig(:age_ranges).present?
    self.veteran_statuses = [allow(housed_scope.available_veteran_stati, filters.dig(:veteran_status).to_i)] if filters.dig(:veteran_status).present?
    self.veteran_status = veteran_statuses.first
  end

  def all_project_scope
    scope = GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports)
    scope = scope.with_project_type(project_type_numbers) if project_type_numbers.present?

    scope
  end

  def project_id
    project_ids.first if project_ids.count == 1
  end

  private def allow(collection, value)
    return collection.keys.detect { |e| e == value&.presence } unless value.is_a?(Array)

    collection.keys & value
  end

  private def housed_scope
    Reporting::Housed
  end

  # Override the default because we want to preserve the empty array when nothing is chosen
  def effective_project_ids
    @effective_project_ids = effective_project_ids_from_projects
    @effective_project_ids += effective_project_ids_from_project_groups
    @effective_project_ids += effective_project_ids_from_organizations
    @effective_project_ids += effective_project_ids_from_data_sources
    @effective_project_ids += effective_project_ids_from_coc_codes

    @effective_project_ids.uniq.reject(&:blank?)
  end
end
