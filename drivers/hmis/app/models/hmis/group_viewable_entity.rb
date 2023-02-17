###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class GroupViewableEntity < GrdaWarehouse::GroupViewableEntity
    acts_as_paranoid

    belongs_to :access_group, class_name: '::Hmis::AccessGroup'
    belongs_to :entity, polymorphic: true
  end
end
