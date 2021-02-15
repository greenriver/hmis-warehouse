###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDetailReports
  extend ActiveSupport::Concern

  included do
    private def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end

    private def filter_for_organizations(scope)
      organization_ids = @filter.organization_ids.reject(&:blank?)
      return scope unless organization_ids.any?

      scope.joins(:organization).
        merge(GrdaWarehouse::Hud::Organization.where(id: organization_ids))
    end

    private def filter_for_projects(scope)
      project_ids = @filter.project_ids.reject(&:blank?)
      return scope unless project_ids.any?

      scope.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(id: project_ids))
    end

    private def filter_for_age_ranges(scope)
      scope.in_age_ranges(@filter.age_ranges)
    end

    private def filter_for_hoh(scope)
      return scope unless @filter.heads_of_household

      scope.heads_of_households
    end

    private def filter_for_coc_codes(scope)
      coc_codes = @filter.coc_codes&.reject(&:blank?)
      return scope unless coc_codes.any?

      scope.in_coc(coc_code: coc_codes)
    end

    private def filter_for_project_types(scope)
      project_type_ids = @filter.project_type_ids
      return scope unless project_type_ids.any?

      scope.in_project_type(project_type_ids)
    end

    private def filter_for_gender(scope)
      return scope unless @filter.gender.present?

      scope.joins(:client).
        merge(GrdaWarehouse::Hud::Client.where(Gender: @filter.gender))
    end

    private def filter_for_race(scope)
      race = @filter.race.present?
      return scope unless race && HUD.races.keys.include?(race)

      scope.joins(:client).
        merge(GrdaWarehouse::Hud::Client.where(race => 1))
    end

    private def filter_for_ethnicity(scope)
      return scope unless @filter.ethnicity.present?

      scope.joins(:client).
        merge(GrdaWarehouse::Hud::Client.where(Ethnicity: @filter.ethnicity))
    end

    private def set_filter
      @filter = ::Filters::DateRangeAndSourcesResidentialOnly.new(filter_params.merge({ user_id: current_user.id }))
    end
  end
end
