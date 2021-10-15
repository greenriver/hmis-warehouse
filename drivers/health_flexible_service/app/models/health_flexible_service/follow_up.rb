###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class FollowUp < HealthBase
    acts_as_paranoid

    belongs_to :patient, class_name: 'Health::Patient', optional: true
    belongs_to :user, class_name: 'User', optional: true
  end
end
