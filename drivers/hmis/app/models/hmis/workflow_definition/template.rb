# frozen_string_literal: true

# Represents a reusable workflow template that defines the structure and rules
# of a workflow process. Templates contain nodes (tasks, events, gateways) connected
# by flows that determine the sequence of execution.
module Hmis::WorkflowDefinition
  class Template < GrdaWarehouseBase
    include SimpleStateMachine
    # override the paper trails `version` method as it conflicts with the `version` col on this table
    has_paper_trail(version: :paper_trail_version)
    acts_as_paranoid

    has_many :nodes, class_name: 'Hmis::WorkflowDefinition::Node', dependent: :destroy
    has_many :flows, class_name: 'Hmis::WorkflowDefinition::Flow', dependent: :destroy
    has_many :instances, class_name: 'Hmis::WorkflowExecution::Instance', dependent: :restrict_with_exception, foreign_key: 'template_id'
    has_many :swimlanes, class_name: 'Hmis::WorkflowDefinition::Swimlane', dependent: :restrict_with_exception, foreign_key: 'template_id'
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

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

    scope :viewable_by, ->(user) { where(data_source_id: user.hmis_data_source_id) }
    scope :ce, -> { where(template_type: 'ce_referral') }
    scope :published, -> { where(status: 'published') }

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

    def describe_as_string
      graph.walk.map(&:describe_as_string).join("\n")
    end

    # Returns a string representation of the workflow template in Mermaid diagram format
    def to_mermaid_diagram
      header = [
        '---',
        "title: #{name}",
        '---',
        'flowchart TD',
      ]
      lines = []
      graph.walk.each do |node|
        lines << node.to_mermaid_node
        lines << node.inflows.map(&:to_mermaid_link)
        lines << node.outflows.map(&:to_mermaid_link)
      end
      (header + lines.flatten.uniq).join("\n")
    end

    def validate
      # Run validations that don't run on lifecycle hooks. (See comments in WorkflowTemplateValidator)
      Hmis::WorkflowDefinition::Validators::WorkflowTemplateValidator.new.validate(self)
    end

    def validate!
      # Run validations that don't run on lifecycle hooks, and raise if they result in any errors.
      validate
      raise ActiveRecord::RecordInvalid, self if errors.any?
    end

    # Returns the form definition that should be used for initiating a direct referral using this workflow.
    # Returns nil if the workflow is not valid for direct referrals. Caller is responsible for error handling (raise or AR validation error)
    def direct_referral_form_definition
      return nil unless published? && template_type&.to_s == 'ce_referral'

      # Walk the graph, passing the entrypoints as starting points so they aren't included in the results
      entrypoint_ids = nodes.entrypoints.pluck(:id)
      walk = graph.walk(entrypoint_ids: entrypoint_ids, stop_when: lambda(&:user_task?))

      # Expect that exactly one user task is returned. (Multiple entrypoints is invalid for direct referrals)
      return nil unless walk.count == 1

      # Expect that task to have a form definition
      walk.sole.form_definition
    end
  end
end
