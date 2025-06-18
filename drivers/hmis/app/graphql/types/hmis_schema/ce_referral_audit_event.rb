###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralAuditEvent < Types::BaseObject
    # object is a Hmis::WorkflowExecution::AuditEvent
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :user, Types::Application::User, null: true
    field :type, HmisSchema::Enums::CeReferralAuditEventType, null: false
    field :step_name, String, null: true

    def step_name
      step = load_ar_association(object, :step)
      return nil unless step.present?

      load_ar_association(step, :node).name
    end

    def type
      case object.event_type
      when 'complete_step'
        'COMPLETE_STEP'
      when 'start_workflow'
        'START_REFERRAL'
      when 'end_workflow'
        case object.event_data['message']
        when Hmis::WorkflowExecution::Engine::REJECT_REFERRAL
          'REJECT_REFERRAL'
        when Hmis::WorkflowExecution::Engine::ACCEPT_REFERRAL
          'ACCEPT_REFERRAL'
        else
          raise "Unexpected referral audit event. ID: #{object.id}. Event data: #{object.event_data}"
        end
      else
        raise "Unexpected referral audit event. ID: #{object.id}. Event type: #{object.event_type}"
      end
    end
  end
end
