###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/hud-reporting/report-drivers.md
Rails.application.config.hud_reports['HudLsa::Generators::Fy2027::Lsa'] = {
  title: 'Longitudinal System Analysis',
  helper: 'hud_reports_lsas_path',
}
