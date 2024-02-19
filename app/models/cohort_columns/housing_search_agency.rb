###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class HousingSearchAgency < Select
    attribute :column, String, lazy: true, default: :housing_search_agency
    attribute :translation_key, String, lazy: true, default: 'Housing Search Agency'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: ->(model, _attr) { "#{model.translation_key} Description" }
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def available_options
      Rails.cache.fetch('all_project_names', expires_in: 5.minutes) do
        agencies = Set.new
        GrdaWarehouse::Hud::Project.distinct.
          joins(:organization).
          order(ProjectName: :asc).
          pluck(o_t[:OrganizationName].to_sql, :ProjectName).
          each do |organization_name, project_name|
            agencies << organization_name
            agencies << "#{organization_name}: #{project_name}"
          end
        agencies.to_a.sort
      end
    end
  end
end
