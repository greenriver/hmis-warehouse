###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Loads both STI subclasses so queries on the base class include their types where eager
# loading is off (the export lookup uses Report.viewable_by). Loading them also registers
# them for archival.
Rails.application.config.to_prepare do
  [
    ContinuumSemiAnnualPerformance::MidYearReport,
    ContinuumSemiAnnualPerformance::EndOfYearReport,
  ].each(&:name)
end
