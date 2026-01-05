###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce
  class DefaultSwimlaneAssignment < ::GrdaWarehouseBase
    self.table_name = 'ce_default_swimlane_assignments'

    acts_as_paranoid

    belongs_to :user, class_name: 'Hmis::User'
    belongs_to :swimlane, class_name: 'Hmis::WorkflowDefinition::Swimlane'
    belongs_to :owner, polymorphic: true

    validates :user, :swimlane, :owner, presence: true
    validates :user_id, uniqueness: { scope: [:owner_type, :owner_id, :swimlane_id] }, if: -> { deleted_at.nil? }
  end
end
