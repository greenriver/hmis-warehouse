###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  class CeAprDrilldownPresenter < DrilldownPresenter
    def extra_fields
      {
        'Question 5' => [:age, :parenting, :veteran, :homeless],
        'Question 6' => [:pii, :universal_data, :financial, :housing, :project, :timeliness, :inactive_records],
        'Question 7' => [:household, :parenting, :project],
        'Question 8' => [:household, :parenting, :project],
        'Question 9' => [:household, :ce, :project],
        'Question 10' => [:ce, :project],
      }
    end
  end
end
