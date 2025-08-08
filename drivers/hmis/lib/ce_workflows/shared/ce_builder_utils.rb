###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

##
# Utility class for scripts that build Coordinated Entry (CE) workflow definitions,
# and any scripts we need to run manually/locally until all CE configuration functionality is in place.
#
# Provides helper methods for deleting, creating, and wiring up workflow templates, events, and related objects.
# Intended for use in Rake tasks or other scripts that automate the setup or teardown of CE workflows.
# Not intended for use in production application logic.
module CeWorkflows::Shared
  class CeBuilderUtils
    # Development utility to build candidate pools.
    # Run this after changing/adding/removing match expressions
    #
    # @param clients [ActiveRecord::Relation, nil] Optional client scope to mark as dirty for processing.
    #   If provided, these clients will be marked dirty and processed along with any other dirty records.
    #   If nil, only processes existing dirty records.
    # @param opportunities [ActiveRecord::Relation, nil] Optional opportunities scope to limit pool building
    # @param progress [Boolean] Whether to show progress during processing
    # @param cleanup_orphans [Boolean] Whether to immediately remove orphaned pools (development only)
    def self.build_candidate_pools(clients: nil, opportunities: nil, progress: false, cleanup_orphans: false)
      # Build candidate pools using the production job
      # This creates/updates pools based on active opportunities and marks them as dirty
      Hmis::Ce::BuildCandidatePoolsJob.new.perform(opportunity_ids: opportunities&.pluck(:id))

      # Optional immediate cleanup for development (production uses time-based cleanup)
      Hmis::Ce::Match::CandidatePool.orphaned.find_each(&:destroy!) if cleanup_orphans

      if clients
        # Mark the specified clients as dirty so they get processed
        Hmis::Ce::ChangeMarker.upsert_or_bump_version(
          'GrdaWarehouse::Hud::Client',
          trackable_ids: clients.pluck(:id),
        )
      end

      # Process all dirty pools and clients using the production job
      # This populates the pools by calling the match engine with the same logic used in production
      hit_max_iterations = false
      10.times do
        break unless Hmis::Ce::ChangeMarker.dirty.exists?

        Hmis::Ce::ProcessChangesJob.new.perform(progress: progress)
        hit_max_iterations = Hmis::Ce::ChangeMarker.dirty.exists?
      end

      return unless hit_max_iterations

      Rails.logger.warn('CeBuilderUtils#build_candidate_pools reached maximum iterations (10). Dirty markers may not be fully processed.')
    end

    # Run this to keep state machine statuses in sync with custom statuses
    def self.create_state_machine_custom_statuses(data_source)
      Hmis::Ce::Referral.state_machine_states.map do |state|
        status = Hmis::Ce::CustomReferralStatus.find_or_initialize_by(
          key: state.to_s,
          data_source: data_source,
        )
        label = case state.to_s
        when 'rejected' then 'Declined'
        else state.to_s.humanize.titleize
        end
        status.name = label
        status.save!
      end
    end

    def self.delete_template_and_associated_data(template_identifier)
      raise 'This method destroys data and should not be run in production' if Rails.env.production?

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
      raise 'This method destroys data and should not be run in production' if Rails.env.production?

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
