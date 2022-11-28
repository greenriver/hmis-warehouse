###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Fy2022
  class Report < ::Report
    include ArelHelper
    def self.report_name
      'LSA - FY 2022'
    end

    def report_group_name
      'Longitudinal System Analysis '
    end

    def file_name options
      "#{name}-#{options['coc_code']}"
    end

    def download_type
      :zip
    end

    def has_options? # rubocop:disable Naming/PredicateName
      true
    end

    def has_custom_form? # rubocop:disable Naming/PredicateName
      true
    end

    def title_for_options
      'Limits'
    end

    def self.available_projects(user:)
      # Project types are integral to LSA business logic; only ES, SH, TH, PSH projects should be available to select as parameters.
      # Section 2.1 requires that the projects available to a user for selection when entering report parameters must be limited to ProjectTypes ES (1), SH (8), TH (2), RRH (13), and PSH (3), so records for other project types are never included when LSAScope = 2.
      # NOTE: app/models/report_generators/lsa/fy2022/base.rb will define a different set for system-wide LSAScope = 1

      project_scope = GrdaWarehouse::Hud::Project.coc_funded.with_hud_project_type([1, 2, 3, 8, 13])
      GrdaWarehouse::Hud::Project.options_for_select(user: user, scope: project_scope)
    end

    def self.available_data_sources
      GrdaWarehouse::DataSource.importable
    end

    def self.available_lsa_scopes
      {
        'System-Wide' => 1,
        'Project-Focused' => 2,
      }
    end
  end
end
