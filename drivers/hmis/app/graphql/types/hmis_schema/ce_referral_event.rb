###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralEvent < Types::BaseObject
    # object is a Hmis::WorkflowExecution::AuditEvent
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :user, Types::Application::User, null: true
    field :type, String, null: false, method: :event_type
    field :step_name, String, null: true

    def step_name
      step = load_ar_association(object, :step)
      return nil unless step.present?

      load_ar_association(step, :node).name
    end

    def type
      # todo @martha - add comments justifying the messiness, or make it less messy
      case object.event_type
      when 'complete_step'
        'Completed Task'
      when 'message_sent'
        case object.event_data['event']
        when 'start_workflow'
          'Started Referral'
        when 'end_workflow'
          object.event_data['message'] == 'reject_referral' ? 'Declined Referral' : 'Accepted Referral'
        else
          ''
        end
      else
        ''
      end
    end
  end
end
