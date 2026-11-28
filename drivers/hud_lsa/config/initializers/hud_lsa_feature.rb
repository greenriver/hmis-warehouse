###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.hud_reports['HudLsa::Generators::Fy2027::Lsa'] = {
  title: 'Longitudinal System Analysis',
  helper: 'hud_reports_lsas_path',
}

# Aliases map retired generators to a definition so old runs stay viewable; they don't make them runnable.
['Fy2022', 'Fy2023', 'Fy2024', 'Fy2026'].each do |year|
  Rails.application.config.hud_report_definition_aliases["HudLsa::Generators::#{year}::Lsa"] = { helper: 'hud_reports_lsas_path' }
end
