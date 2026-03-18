###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class TransferEnrollmentProjectJob < BaseJob # move to services/
    # Transfers a set of enrollments from their current project to a target project.
    # This is intended to be used to fulfill support requests to move enrollments between projects.
    # In the future, it may be used to back a user-facing admin tool to transfer enrollments (#5767).
    #
    # Behavior
    # - Takes an array of enrollment IDs, source project ID, target project ID, and optional dry_run flag
    # - Validates that all enrollments exist and belong to the source project
    # - Validates that all household members are included in the transfer (cannot transfer partial households)
    # - Transfers enrollments to target project by updating project_pk and project_id
    # - Releases any assigned units
    # - Handles all transfers within a single transaction
    #
    # Transfer Process
    # - Updates enrollment.project_pk to target project
    # - Updates enrollment.project_id to target project's HUD project ID
    # - Releases current unit assignment (if applicable)
    def perform(enrollment_ids:, source_project_id:, target_project_id:, dry_run: false)
      # Validate inputs
      source_project = Hmis::Hud::Project.hmis.find_by(id: source_project_id)
      raise "Source project not found: #{source_project_id}" unless source_project.present?

      target_project = Hmis::Hud::Project.hmis.find_by(id: target_project_id)
      raise "Target project not found: #{target_project_id}" unless target_project.present?

      raise 'Source and target project must be in the same data source' unless source_project.data_source_id == target_project.data_source_id

      enrollments = source_project.enrollments.where(id: enrollment_ids).preload(:project, :client, :current_unit)
      raise "Some enrollments not found in source project. Requested: #{enrollment_ids.size}, Found: #{enrollments.size}" unless enrollments.size == enrollment_ids.size

      # Validate that all household members are included in the transfer
      validate_household_members_included(enrollments, source_project)

      Rails.logger.info "#{enrollments.size} Enrollments to transfer from '#{source_project.name}' to '#{target_project.name}'"
      Rails.logger.info "To transfer: #{enrollments.in_progress.count} incomplete, #{enrollments.open_excluding_wip.count} active, #{enrollments.exited.count} exited"

      return if dry_run

      Hmis::Hud::Base.transaction do
        enrollments.each do |enrollment|
          transfer_enrollment(enrollment, target_project)
        end
      end

      Rails.logger.info 'Completed successfully'
    end

    private

    def transfer_enrollment(enrollment, target_project)
      # Update project association
      enrollment.project_pk = target_project.id
      enrollment.project_id = target_project.project_id unless enrollment.project_id.blank? # skip for WIP enrollments

      # Release unit assignment (if applicable)
      enrollment.release_unit!(user: system_user)
      enrollment.save!
    end

    # Validate that all household members are included in the transfer. Raises an error if not.
    # We could adjust this to add an option to automatically transfer all household members if desired.
    def validate_household_members_included(enrollments, source_project)
      enrollment_ids = enrollments.pluck(:id)
      enrollment_ids_with_hh_members = source_project.enrollments.where(household_id: enrollments.select(:household_id)).pluck(:id)

      missing_enrollment_ids = enrollment_ids_with_hh_members.uniq - enrollment_ids.uniq
      return unless missing_enrollment_ids.any?

      raise "Cannot transfer partial household. Missing household member enrollment IDs: #{missing_enrollment_ids.join(', ')}"
    end

    def system_user
      @system_user ||= Hmis::User.system_user
    end
  end
end
