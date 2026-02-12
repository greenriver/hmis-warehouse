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
    # Development utility
    # Run this after changing/adding/removing match expressions
    #
    # @param clients [ActiveRecord::Relation, nil] Optional client scope to mark as dirty for processing.
    #   If provided, these clients will be marked dirty and processed along with any other dirty records.
    #   If nil, only processes existing dirty records.
    # @param unit_groups [ActiveRecord::Relation, nil] Optional unit groups scope to limit pool building.
    # @param progress [Boolean] Whether to show progress during processing
    # @param cleanup_orphans [Boolean] Whether to immediately remove orphaned pools (development only)
    # @param force_reprocessing [Boolean] Whether to mark all pools as dirty for reprocessing.
    def self.build_candidate_pools(clients: nil, unit_groups: nil, progress: false, cleanup_orphans: false, force_reprocessing: false)
      # Build candidate pools by calling the builder directly.
      # This creates/updates pools based on unit groups and their rules.
      Hmis::Ce::Match::CandidatePool.lock_for_maintenance! do
        Hmis::Ce::Match::CandidatePoolBuilder.call(
          unit_group_ids: unit_groups&.pluck(:id),
          force_reprocessing: force_reprocessing,
        )
      end

      # Optional immediate cleanup for development (production uses time-based cleanup)
      Hmis::Ce::Match::CandidatePool.orphaned.find_each(&:destroy!) if cleanup_orphans

      if clients
        # Mark the specified clients as dirty so they get processed
        Hmis::Ce::ChangeMarker.upsert_or_bump_version(
          'GrdaWarehouse::Hud::Client',
          trackable_ids: clients.pluck(:id),
        )
      end

      # Process all dirty pools and clients using the production jobs
      # This populates the pools by calling the match engine with the same logic used in production
      hit_max_iterations = false
      10.times do
        break unless Hmis::Ce::ChangeMarker.dirty.exists?

        Hmis::Ce::ProcessClientsJob.new.perform(progress: progress)
        Hmis::Ce::ProcessPoolsJob.new.perform(progress: progress)
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
      # Find opportunities through unit groups that use this template
      unit_groups = Hmis::UnitGroup.where(workflow_template_identifier: template_identifier).
        or(Hmis::UnitGroup.where(direct_referral_workflow_template_identifier: template_identifier))
      opportunities = Hmis::Ce::Opportunity.joins(:unit).where(hmis_units: { hmis_unit_group_id: unit_groups.select(:id) })
      instances = Hmis::WorkflowExecution::Instance.where(template: templates)
      steps = Hmis::WorkflowExecution::Step.where(instance: instances)
      referrals = Hmis::Ce::Referral.where(workflow_instance: instances)

      Hmis::Ce::ReferralNote.where(referral: referrals).find_each(&:destroy!)
      Hmis::Ce::ReferralParticipant.where(referral: referrals).find_each(&:destroy!)
      referrals.find_each(&:destroy!)

      Hmis::Ce::OpportunityCategorization.where(opportunity: opportunities).find_each(&:destroy!)
      opportunities.find_each(&:destroy!)

      Hmis::WorkflowExecution::AuditEvent.where(instance: instances).find_each(&:destroy!)
      instances.find_each(&:destroy!)
      Hmis::WorkflowExecution::StepAssignment.where(step: steps).find_each(&:destroy!)
      steps.find_each(&:destroy!)

      Hmis::WorkflowDefinition::Flow.where(template: templates).find_each(&:destroy!)
      Hmis::WorkflowDefinition::Node.where(template: templates).find_each(&:destroy!)
      Hmis::WorkflowDefinition::Swimlane.where(template: templates).find_each(&:destroy!)
      templates.find_each(&:destroy!)
    end

    def self.delete_template_version(identifier:, version:)
      raise 'This method destroys data and should not be run in production' if Rails.env.production?

      template = Hmis::WorkflowDefinition::Template.find_by!(
        identifier: identifier,
        version: version,
      )

      puts "Deleting CE data associated with template #{template.id} (#{identifier} v#{version})"

      instances = Hmis::WorkflowExecution::Instance.where(template: template)
      steps = Hmis::WorkflowExecution::Step.where(instance: instances)
      referrals = Hmis::Ce::Referral.where(workflow_instance: instances)

      Hmis::Ce::ReferralNote.where(referral: referrals).find_each(&:destroy!)
      Hmis::Ce::ReferralParticipant.where(referral: referrals).find_each(&:destroy!)
      referrals.find_each(&:destroy!)

      Hmis::WorkflowExecution::AuditEvent.where(instance: instances).find_each(&:destroy!)
      instances.find_each(&:destroy!)
      Hmis::WorkflowExecution::StepAssignment.where(step: steps).find_each(&:destroy!)
      steps.find_each(&:destroy!)

      Hmis::WorkflowDefinition::Flow.where(template: template).find_each(&:destroy!)
      Hmis::WorkflowDefinition::Node.where(template: template).find_each(&:destroy!)
      Hmis::WorkflowDefinition::Swimlane.where(template: template).find_each(&:destroy!)

      template.destroy!
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

    # Given the template information and version, find the corresponding draft template, or create it if it doesn't exist.
    # This method will raise an error if the template with that version already exists and isn't a draft.
    # Used by workflow builders that initialize and iterate on an unpublished template until it is ready to be published.
    # See for example README_FOR_PH_CE_WORKFLOWS.md
    def self.find_or_create_draft_template(identifier:, name:, data_source:, version:)
      Hmis::WorkflowDefinition::Template.find_or_create_by!(
        identifier: identifier,
        name: name,
        data_source: data_source,
        template_type: 'ce_referral',
        status: 'draft',
        version: version,
      )
    end

    def self.publish_template(template:)
      raise "Template with status #{template.status} cannot be published" unless template.draft?

      template_to_retire = Hmis::WorkflowDefinition::Template.find_by(
        identifier: template.identifier,
        data_source: template.data_source,
        status: 'published',
      )
      raise "Template with version #{template.version} cannot be published, the current published version is #{template_to_retire.version}" if template_to_retire.present? && template_to_retire.version != template.version - 1

      Hmis::WorkflowDefinition::Template.transaction do
        template_to_retire&.retire!
        template.publish!
      end
    end

    def self.unpublish_template(template:) # Development helper. Do not use in production
      raise 'Should not be run in production' if Rails.env.production?
      raise "Template with status #{template.status} cannot be unpublished" unless template.published?

      template_to_republish = Hmis::WorkflowDefinition::Template.where(
        identifier: template.identifier,
        data_source: template.data_source,
        status: 'retired',
      ).max_by(&:version)

      Hmis::WorkflowDefinition::Template.transaction do
        template.update!(status: 'draft')
        template_to_republish&.update!(status: 'published')
      end
    end

    def self.find_or_create_start_event(template)
      event = Hmis::WorkflowDefinition::StartEvent.find_or_initialize_by(
        name: 'Start Referral',
        template: template,
      )
      event.trigger_config = [
        {
          event: 'start_workflow',
          message: 'start_referral',
        },
      ]
      event.save!
      event
    end

    def self.find_or_create_accept_event(template, name: 'Referral Accepted', update_ce_event: false)
      event = Hmis::WorkflowDefinition::EndEvent.find_or_initialize_by(
        name: name,
        template: template,
      )

      event.trigger_config = [
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
      ].compact

      event.save!
      event
    end

    def self.create_gateway(template, name, gateway_type: 'exclusive')
      Hmis::WorkflowDefinition::Gateway.create!(
        template: template,
        gateway_type: gateway_type,
        name: "#{gateway_type.capitalize} Gateway: #{name}",
      )
    end

    def self.find_or_create_gateway(template, name, gateway_type: 'exclusive')
      Hmis::WorkflowDefinition::Gateway.find_or_create_by!(
        template: template,
        gateway_type: gateway_type,
        name: "#{gateway_type.capitalize} Gateway: #{name}",
      )
    end

    def self.find_or_create_decline_event(template, name: 'Referral Declined', ce_event_result: nil)
      raise 'set_ce_event_result must be nil or a valid referral result code (2 or 3)' if ce_event_result && !['2', '3'].include?(ce_event_result.to_s)

      event = Hmis::WorkflowDefinition::EndEvent.find_or_initialize_by(
        name: name,
        template: template,
      )

      event.trigger_config = [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
        },
        *(
          if ce_event_result
            [
              {
                event: 'end_workflow',
                message: 'set_ce_event_result',
                params: { referral_result: ce_event_result.to_s },
              },
            ]
          end
        ),
      ].compact

      event.save!
      event
    end
  end
end
