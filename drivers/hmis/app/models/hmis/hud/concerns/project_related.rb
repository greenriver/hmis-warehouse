###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::ProjectRelated
  extend ActiveSupport::Concern

  included do
    scope :viewable_by, ->(user) do
      joins(:project).merge(Hmis::Hud::Project.viewable_by(user))
    end

    scope :editable_by, ->(user) do
      joins(:project).merge(Hmis::Hud::Project.editable_by(user))
    end
  end
end
