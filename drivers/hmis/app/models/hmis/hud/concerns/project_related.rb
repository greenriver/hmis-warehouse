###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::ProjectRelated
  extend ActiveSupport::Concern

  included do
    # hide previous declaration of :viewable_by, we'll use this one
    replace_scope :viewable_by, ->(user) do
      joins(:project).merge(Hmis::Hud::Project.viewable_by(user))
    end
  end
end
