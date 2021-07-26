###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::Outcomes::OutcomesFilter < Filters::FilterBase
  # For use in the the view
  attribute :gender, Symbol, default: :all
  attribute :race, Symbol, default: :all
  attribute :ethnicity, Symbol, default: :all
  attribute :veteran_status, Symbol, default: :all

  def set_from_params(filters) # rubocop:disable Naming/AccessorMethodName
    super(filters)

    self.genders = [allow(housed_scope.available_genders, filters.dig(:gender).to_i)] if filters.dig(:gender).present?
    self.gender = genders.first
    self.races = [allow(housed_scope.available_races, filters.dig(:race))]
    self.race = races.first
    self.ethnicities = [allow(housed_scope.available_ethnicities, filters.dig(:ethnicity).to_i)] if filters.dig(:ethnicity).present?
    self.ethnicity = ethnicities.first
    self.veteran_statuses = [allow(housed_scope.available_veteran_stati, filters.dig(:veteran_status).to_i)] if filters.dig(:veteran_status).present?
    self.veteran_status = veteran_statuses.first
  end

  def all_project_scope
    scope = GrdaWarehouse::Hud::Project.viewable_by(user)
    scope = scope.with_project_type(project_type_numbers) if project_type_numbers.present?

    scope
  end

  def project_id
    project_ids.first if project_ids.count == 1
  end

  private def allow(collection, value)
    collection.keys.detect { |e| e == value&.presence }
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
