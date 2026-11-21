###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Aliases map retired generators to a definition so old runs stay viewable; they don't make them runnable.
%w[Fy2020 Fy2022].each do |year|
  Rails.application.config.hud_report_definition_aliases["HudDataQualityReport::Generators::#{year}::Generator"] = { helper: 'hud_reports_dqs_path' }
end
