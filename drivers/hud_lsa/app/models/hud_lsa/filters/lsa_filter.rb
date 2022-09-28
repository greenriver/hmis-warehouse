###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Filters
  class LsaFilter < ::Filters::HudFilterBase
    validates_presence_of :coc_code

    # This lets parent validation pass
    def coc_codes
      [coc_code]
    end

    def params_for_display
      params = known_params.flat_map do |k|
        if k.is_a?(Hash)
          k.keys
        else
          k
        end
      end
      # LSA uses coc_code
      params - [:coc_codes]
    end

    def effective_project_ids
      @effective_project_ids = super.reject(&:zero?)

      # limit the project IDs to those that are relevant to the LSA
      if @effective_project_ids.any?
        @effective_project_ids &= GrdaWarehouse::Hud::Project.viewable_by(user).
          in_coc(coc_code: coc_code).
          with_hud_project_type(relevant_project_types).
          coc_funded.
          pluck(:id)
      else
        # For system-wide just limit by project type and coc_funded
        GrdaWarehouse::Hud::Project.viewable_by(user).
          in_coc(coc_code: coc_code).
          with_hud_project_type(relevant_project_types).
          coc_funded.
          pluck(:id).sort
      end
    end

    # Confirmed with HUD only project types 1, 2, 3, 8, 9, 10, 13 need to be included in hmis_ tables.
    def relevant_project_types
      [1, 2, 3, 8, 9, 10, 13].freeze
    end
  end
end
