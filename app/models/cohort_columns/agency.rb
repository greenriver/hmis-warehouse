###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Agency < Select
    include ArelHelper
    attribute :column, String, lazy: true, default: :agency
    attribute :translation_key, String, lazy: true, default: 'Agency'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

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
        agencies << 'Confidential Project'
        agencies.to_a.sort
      end
    end
  end
end
