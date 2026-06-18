###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Concerns::ProjectRelated
  extend ActiveSupport::Concern

  included do
    has_paper_trail(meta: { project_id: ->(r) { r.project&.id } })

    # hide previous declaration of :viewable_by, we'll use this one
    replace_scope :viewable_by, ->(user) do
      joins(:project).merge(Hmis::Hud::Project.viewable_by(user))
    end
  end
end
