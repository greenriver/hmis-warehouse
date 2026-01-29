###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Validates CE Referral Workflow Templates for CE-specific requirements.
# This validator is called by the main WorkflowTemplateValidator for templates with type 'ce_referral'.
module Hmis::Ce
  class ReferralWorkflowTemplateValidator
    def validate(record)
      validate_decline_reasons(record)
    end

    private

    # Validates that nodes with decline reason triggers are properly configured:
    # - Nodes with 'set_referral_decline_reason' triggers must be user tasks
    # - The form on each such node must have a choice item with the decline reason link_id
    # - All decline reason codes collected by the forms must exist in the database as ReferralDeclineReasons
    def validate_decline_reasons(record)
      decline_reason_nodes = record.nodes.filter do |node|
        node.trigger_config&.any? { |trigger| trigger['message'] == 'set_referral_decline_reason' } || false
      end

      link_id = Hmis::Ce::ReferralMessageHandler::DECLINE_REASON_LINK_ID

      decline_reason_keys = decline_reason_nodes.map do |node|
        unless node.user_task?
          record.errors.add(:base, "Node '#{node.name}' is not a user task, so it cannot set a decline reason.")
          next nil
        end
        form = node.form_definition

        unless form.link_id_item_hash[link_id].present? && form.link_id_item_hash[link_id]['pick_list_options'].present?
          record.errors.add(:base, "Decline reason form '#{form.identifier}' must collect decline reason on a choice item with link_id '#{link_id}'")
          next nil
        end

        form.link_id_item_hash[link_id]['pick_list_options'].map { |option| option['code'] }
      end.compact.flatten.to_set

      decline_reasons = Hmis::Ce::ReferralDeclineReason.where(key: decline_reason_keys, data_source_id: record.data_source_id)
      missing_decline_reasons = decline_reason_keys - decline_reasons.pluck(:key).to_set
      record.errors.add(:base, "The following decline reasons are collected by the form, but not defined in the database: #{missing_decline_reasons.join(', ')}") if missing_decline_reasons.any?
    end
  end
end
