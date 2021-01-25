###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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

    self.genders = [allow(housed_scope.available_genders, filters.dig(:gender)&.to_i)]
    self.gender = genders.first
    self.races = [allow(housed_scope.available_races, filters.dig(:race))]
    self.race = races.first
    self.ethnicities = [allow(housed_scope.available_ethnicities, filters.dig(:ethnicity)&.to_i)]
    self.ethnicity = ethnicities.first
    self.veteran_statuses = [allow(housed_scope.available_veteran_stati, filters.dig(:veteran_status)&.to_i)]
    self.veteran_status = veteran_statuses.first
  end

  def all_project_scope
    GrdaWarehouse::Hud::Project.viewable_by(user).with_project_type(project_type_numbers)
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
end
