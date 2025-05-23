# frozen_string_literal: true

# Represents a reusable workflow template that defines the structure and rules
# of a workflow process. Templates contain nodes (tasks, events, gateways) connected
# by flows that determine the sequence of execution.
module Hmis::WorkflowDefinition
  class Template < GrdaWarehouseBase
    include SimpleStateMachine

    has_many :nodes, class_name: 'Hmis::WorkflowDefinition::Node', dependent: :destroy
    has_many :flows, class_name: 'Hmis::WorkflowDefinition::Flow', dependent: :destroy
    has_many :instances, class_name: 'Hmis::WorkflowExecution::Instance', dependent: :restrict_with_exception, foreign_key: 'template_id'
    has_many :swimlanes, class_name: 'Hmis::WorkflowDefinition::Swimlane', dependent: :restrict_with_exception, foreign_key: 'template_id'
    has_many :ce_opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception

    validates :name, presence: true
    validates :status, presence: true
    validates :version, presence: true
    validate :unique_status_per_identifier

    state_machine_config column: 'status' do
      state :draft, initial: true
      state :retired
      state :published

      event :publish do
        transitions from: :draft, to: :published
      end

      event :retire do
        transitions from: :published, to: :retired
      end
    end

    scope :viewable_by, ->(_user) { all }

    scope :latest_versions, -> do
      # Returns the most recent Template version per identifier
      one_for_column([:version], source_arel_table: arel_table, group_on: :identifier)
    end

    def graph(preloads: nil) # Caller can optionally pass additional attributes to preload, to avoid n+1s
      Hmis::WorkflowDefinition::Graph.new(nodes.preload(:outflows, *preloads))
    end

    def unique_status_per_identifier
      return unless ['draft', 'published'].include?(status)

      return unless self.class.where(identifier: identifier, status: status).
        where.not(id: id).
        exists?

      errors.add(:base, "There can only be one #{status} template for the identifier #{identifier}.")
    end
  end
end
