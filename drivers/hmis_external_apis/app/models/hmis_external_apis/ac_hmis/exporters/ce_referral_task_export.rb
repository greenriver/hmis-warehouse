###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  class CeReferralTaskExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def run!
      Rails.logger.info 'Generating content of CE Referral Task export'

      write_row(columns)
      total = referral_tasks.count

      Rails.logger.info "There are #{total} referral tasks to export"

      referral_tasks.find_each.with_index do |task, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?
        referral_id = instance_id_to_referral_id[task.instance_id]
        raise 'Missing referral ID' unless referral_id

        values = [
          task.id,                # TaskID
          referral_id,            # ReferralID
          task.instance.template.identifier, # ReferralWorkflowIdentifier
          task.node.id,           # NodeID
          task.node.name,         # NodeName
          task.status,            # Status
          task.available_at,      # AvailableAt
          task.completed_at,      # CompletedAt
          task.updated_by&.id,    # CompletedByUserID (maps to User.csv) - TODO fix
        ]
        write_row(values)
      end
    end

    private

    # backed by ce_referral_tasks table
    def columns
      [
        'TaskID',                   # Unique ID for this task
        'ReferralID',               # Referral ID that this task belongs to
        'ReferralWorkflowIdentifier', # Identifier of the referral workflow template
        'NodeID',                     # ID of the node that defines this task
        'NodeName',                   # Name of the node that defines this task
        'Status',                     # Status of the task
        'AvailableAt',                # Timestamp when the task was made available
        'CompletedAt',                # Timestamp when the task was completed
        'CompletedByUserID',          # ID of the user who completed the task (maps to User.csv)
      ]
    end

    def referral_tasks
      Hmis::WorkflowExecution::Step.
        joins(instance: :template).
        merge(Hmis::WorkflowDefinition::Template.ce). # drop steps for non-CE templates
        preload(:node, :updated_by, instance: [:template])
    end

    def instance_id_to_referral_id
      Hmis::Ce::Referral.pluck(:workflow_instance_id, :id).to_h
    end
  end
end
