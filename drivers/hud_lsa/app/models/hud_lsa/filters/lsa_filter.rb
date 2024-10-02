###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Filters
  class LsaFilter < ::Filters::HudFilterBase
    validates_presence_of :coc_code
    attribute :default_project_type_codes, Array, default: [:es_nbn, :es_entry_exit, :th, :psh, :sh, :oph, :rrh]
    attribute :coc_codes, Array, default: [GrdaWarehouse::Config.default_site_coc_codes&.first]

    # This lets parent validation pass
    def coc_codes
      [coc_code]
    end

    # If a single day for the PIT has been selected, set the start and end dates from the 'on' date
    def update(filters)
      # CoC Codes get treated in some odd ways, try to standardize, LSA & HIC can only run on one CoC at a time
      raise ArgumentError, 'Only one CoC code is allowed' if filters[:coc_code].is_a?(Array) && filters[:coc_code].reject(&:blank?).count > 1

      filters[:coc_code] = filters[:coc_code].reject(&:blank?).first if filters[:coc_code].is_a?(Array)
      super

      filters = filters.to_h.with_indifferent_access
      pit_date = filters.dig(:on)&.to_date
      return unless pit_date.present?

      self.start = pit_date
      self.end = pit_date
      self
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
        @effective_project_ids &= GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).
          in_coc(coc_code: coc_code).
          with_hud_project_type(relevant_project_types).
          coc_funded.
          pluck(:id)
      else
        # For system-wide just limit by project type and coc_funded
        GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).
          in_coc(coc_code: coc_code).
          with_hud_project_type(relevant_project_types).
          coc_funded.
          pluck(:id).sort
      end
    end

    # Confirmed with HUD only project types 0, 1, 2, 3, 8, 9, 10, 13 need to be included in hmis_ tables.
    def relevant_project_types
      self.class.relevant_project_types
    end

    def self.relevant_project_types
      [0, 1, 2, 3, 8, 9, 10, 13].freeze
    end
  end
end
