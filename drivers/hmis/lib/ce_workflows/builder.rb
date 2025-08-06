module CeWorkflows
  class Builder
    def self.delete_template_and_associated_data(template_identifier)
      puts "Deleting existing CE data associated with #{template_identifier}"

      templates = Hmis::WorkflowDefinition::Template.where(identifier: template_identifier)
      opportunities = Hmis::Ce::Opportunity.where(workflow_template_identifier: template_identifier)
      instances = Hmis::WorkflowExecution::Instance.where(template: templates)
      steps = Hmis::WorkflowExecution::Step.where(instance: instances)
      referrals = Hmis::Ce::Referral.where(workflow_instance: instances)

      Hmis::Ce::ReferralNote.where(referral: referrals).destroy_all
      Hmis::Ce::ReferralParticipant.where(referral: referrals).destroy_all
      referrals.destroy_all

      Hmis::Ce::OpportunityCategorization.where(opportunity: opportunities).destroy_all
      opportunities.destroy_all

      Hmis::WorkflowExecution::AuditEvent.where(instance: instances).destroy_all
      instances.destroy_all
      Hmis::WorkflowExecution::StepAssignment.where(step: steps).destroy_all
      steps.destroy_all

      Hmis::WorkflowDefinition::Flow.where(template: templates).destroy_all
      Hmis::WorkflowDefinition::Node.where(template: templates).destroy_all
      Hmis::WorkflowDefinition::Swimlane.where(template: templates).destroy_all
      templates.destroy_all
    end

    def self.delete_form_definitions(form_definition_identifiers)
      puts "Deleting form definitions #{form_definition_identifiers.join(', ')}"

      # Temporarily disable the callback that prevents destroying published forms
      Hmis::Form::Definition.skip_callback(:destroy, :before, :can_be_destroyed)
      Hmis::Form::Definition.where(role: 'CE_REFERRAL_STEP', identifier: form_definition_identifiers).destroy_all
      Hmis::Form::Definition.set_callback(:destroy, :before, :can_be_destroyed) # re-enable callback
    end

    def self.create_template(identifier, name, data_source)
      Hmis::WorkflowDefinition::Template.create!(
        identifier: identifier,
        name: name,
        data_source: data_source,
        template_type: 'ce_referral',
        status: 'published',
        version: 0,
      )
    end

    def self.create_start_event(template)
      Hmis::WorkflowDefinition::StartEvent.create!(
        name: 'Start Referral',
        template: template,
        trigger_config: [
          {
            event: 'start_workflow',
            message: 'start_referral',
          },
        ],
      )
    end

    def self.create_accept_event(template, update_ce_event: false)
      Hmis::WorkflowDefinition::EndEvent.create!(
        name: 'Referral Accepted',
        template: template,
        trigger_config: [
          {
            event: 'end_workflow',
            message: Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE,
          },
          *(
            if update_ce_event
              [
                {
                  event: 'end_workflow',
                  message: 'set_ce_event_result',
                  params: { referral_result: '1' },
                },
              ]
            end
          ),
        ].compact,
      )
    end

    def self.create_gateway(template, name, gateway_type: 'exclusive')
      Hmis::WorkflowDefinition::Gateway.create!(
        template: template,
        gateway_type: gateway_type,
        name: "#{gateway_type.capitalize} Gateway: #{name}",
      )
    end

    def self.create_decline_event(template)
      Hmis::WorkflowDefinition::EndEvent.create!(
        name: 'Referral Declined',
        template: template,
        trigger_config: [
          {
            event: 'end_workflow',
            message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
          },
        ],
      )
    end
  end
end