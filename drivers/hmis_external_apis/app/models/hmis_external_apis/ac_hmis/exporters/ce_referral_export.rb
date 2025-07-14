###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  class CeReferralExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    # Generates the content of the CE Referral export
    # TODO: add Custom Status field to export
    def run!
      Rails.logger.info 'Generating content of CE Referral export'

      write_row(columns)
      total = referrals.count

      Rails.logger.info "There are #{total} referrals to export"

      referrals.find_each.with_index do |referral, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?
        warehouse_id = referral.client.warehouse_id
        next unless warehouse_id.present?

        unit = referral.opportunity.unit
        unit_type_name = unit.unit_type&.description
        target_project = referral.target_project
        source_project = referral.source_enrollment&.project

        values = [
          referral.id,                           # ReferralID
          referral.workflow_template.identifier, # ReferralWorkflowIdentifier
          warehouse_id,                          # PersonalID matching HMIS CSV export
          unit.id,                               # UnitID
          unit_type_name,                        # UnitTypeName
          target_project.project_id,             # TargetProjectID (maps to Project.csv)
          target_project.project_name,           # TargetProjectName
          referral.status,                       # ReferralStatus
          referral.referred_by_id,               # FIXME: map to HUD UserID
          referral.target_enrollment_id,         # TargetEnrollmentID
          referral.source_enrollment_id,         # SourceEnrollmentID
          source_project&.project_id,            # SourceProjectID (maps to Project.csv)
          source_project&.project_name,          # SourceProjectName
          referral.completed_at,                 # CompletedAt
          referral.created_at,                   # CreatedAt
          referral.updated_at,                   # UpdatedAt
        ]
        write_row(values)
      end
    end

    private

    # backed by ce_referrals table
    def columns
      [
        'ReferralID',                 # Unique ID for this referral
        'ReferralWorkflowIdentifier', # Identifier of the referral workflow template
        'PersonalID',                 # Destination ID of client being referred
        'UnitID',                     # Unique ID of the unit being referred to
        'UnitTypeName',               # Name of the unit type
        'TargetProjectID',            # ID of the target project (maps to Project.csv)
        'TargetProjectName',          # Name of the target project
        'ReferralStatus',             # Current Referral Status
        'ReferredByUserID',           # ID of the user who referred the client (maps to User.csv)
        'TargetEnrollmentID',         # Target Enrollment ID, if referral resulted in an enrollment (maps to Enrollment.csv)
        'SourceEnrollmentID',         # Source Enrollment ID in the sending project (maps to Enrollment.csv)
        'SourceProjectID',            # ID of the source project (maps to Project.csv)
        'SourceProjectName',          # Name of the source project
        'CompletedAt',                # Timestamp when the referral was completed
        'CreatedAt',                  # Timestamp when the referral was created
        'UpdatedAt',                  # Timestamp when the referral was last updated
      ]
    end

    def referrals
      Hmis::Ce::Referral.
        joins(client: :warehouse_client_source).
        preload(
          :target_project, # to get project name/id
          :workflow_template, # to get workflow identifier
          source_enrollment: [:project], # to get source project name/id
          client: [:warehouse_client_source], # to get destination id
          opportunity: { unit: [:unit_type] }, # to get unit type name
        )
    end
  end
end
