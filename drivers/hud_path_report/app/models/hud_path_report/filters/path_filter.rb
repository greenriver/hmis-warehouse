###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPathReport::Filters
  class PathFilter < ::Filters::HudFilterBase
    # Don't sent any defaults for project types, they get used in a variety of places and
    # make it impossible to run a report that doesn't include all projects in a type
    def default_project_type_codes
      []
    end

    def project_type_code_options_for_select
      HudHelper.util.project_type_group_titles.select { |k, _| k.in?(path_project_types) }.freeze.invert
    end

    def path_project_types_for_select
      HudHelper.util.project_type_group_titles.select { |k, _| k.in?(path_project_types) }.invert.freeze
    end

    def path_project_type_ids
      path_project_types.map { |s| HudHelper.util.performance_reporting[s] }.flatten
    end

    def path_project_types
      HudHelper.util.path_project_type_codes
    end
  end
end
