###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Wip < Hmis::HmisBase
  TodoOrDie('Remove Hmis::WIP and db table', by: '2024-10-01')
  acts_as_paranoid
end
