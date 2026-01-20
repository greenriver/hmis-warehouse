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

    # Fetch assignments for a project, including inherited assignments from org and data source
    scope :for_project, ->(project) do
      swimlane_scope = Hmis::WorkflowDefinition::Swimlane.
        joins(:template).
        merge(Hmis::WorkflowDefinition::Template.ce.published.used_in_projects([project.id]))

      owners = [project, project.organization, project.data_source].compact
      joins(:swimlane).merge(swimlane_scope).with_owners(owners)
    end

    # Helper scope to fetch assignments for multiple owners at once
    scope :with_owners, ->(owners) do
      return Hmis::Ce::DefaultSwimlaneAssignment.none if owners.blank?

      # Group owners by class to build efficient OR conditions
      owner_groups = owners.compact.group_by(&:class)

      # Build Arel predicates for each owner type
      predicates = owner_groups.map do |klass, items|
        arel_table[:owner_type].eq(klass.name).
          and(arel_table[:owner_id].in(items.map(&:id)))
      end

      # Combine all predicates with OR
      combined_predicate = predicates.reduce { |combined, predicate| combined.or(predicate) }
      where(combined_predicate)
    end
  end
end
