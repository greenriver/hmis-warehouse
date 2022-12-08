###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/boston-cas/blob/production/LICENSE.md
###

class CasAccess::EntityViewPermission < CasBase
  acts_as_paranoid

  belongs_to :entity, polymorphic: true
  belongs_to :user
  belongs_to :agency
end
