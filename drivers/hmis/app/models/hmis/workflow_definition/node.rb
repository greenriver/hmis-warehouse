# STI base class for configuration
module Hmis::WorkflowDefinition
  class Node < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :outflows, class_name: 'Hmis::WorkflowDefinition::Flow', foreign_key: 'source_node_id', dependent: :destroy
    has_many :inflows, class_name: 'Hmis::WorkflowDefinition::Flow', foreign_key: 'target_node_id', dependent: :destroy

    validate :check_trigger_config_format

    scope :entrypoints, -> { where(type: 'Hmis::WorkflowDefinition::StartEvent') }

    def entrypoint? = false
    def task? = false

    # [
    #   { event: 'step_completed', message: 'send_notification', params: params },
    # ]
    def triggers
      (trigger_config || []).map { |item| OpenStruct.new(item) }
    end

    # helper for connecting nodes
    def connect_to!(target_node, condition: nil, position: nil)
      position ||= (outflows.map(&:position).max || 0) + 1
      outflows.create!(
        template: template,
        target_node: target_node,
        position: position,
        condition: condition,
      )
    end

    protected

    def check_trigger_config_format
      return unless trigger_config.is_a?(Array)

      trigger_config.each_with_index do |item, index|
        next if item.is_a?(Hash) && item['event'].present? && item['message'].present?

        errors.add(:config_data, "item at index #{index} ss invalid")
      end
    end
  end
end
