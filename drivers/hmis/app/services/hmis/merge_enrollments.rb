# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  # Merges enrollment_to_destroy into enrollment_to_retain: moves all related records
  # to the retained enrollment, then destroys the duplicate enrollment.
  # Validates that both enrollments belong to the same client, same project, and same data source.
  #
  # === When to use
  #
  # Use only when you have confirmed duplicate enrollments for the same client in the same
  # project (e.g. duplicate data entry) and you want to consolidate them into a single enrollment.
  # This is a support/operational tool. May be extended to user-initiated application flows in the future (#5728).
  #
  # === WARNING — Use with caution
  #
  # This operation is **unsafe** and can cause data loss if used incorrectly. Use it **only**
  # as a support operation after carefully reviewing both enrollments and their associated
  # records. Always run with +dry_run: true+ first and verify the reported changes before
  # performing a real merge.
  #
  # === Related Records
  #
  # This operation moves related records from the enrollment to destroy to the enrollment to retain.
  # Review the associations listed in composite_association_names and integer_moves for the list of records that will be moved.
  #
  # === Intake and exit assessments
  #
  # Intake and exit assessments on enrollment_to_destroy are NOT moved, because only one Intake/Exit per
  # enrollment is allowed. They are soft deleted when the enrollment is removed. Before merging,
  # you must verify that enrollment_to_retain has all required intake/exit information; otherwise the data will be lost.
  #
  # === Usage
  #
  #   1. Always dry run first:
  #      merge = Hmis::MergeEnrollments.new(enrollment_to_retain: retain_id, enrollment_to_destroy: destroy_id)
  #      merge.valid?                    # => true or false
  #      merge.run!(dry_run: true)        # Inspect output; confirm no surprises
  #
  #   2. Only after reviewing, perform the merge:
  #      merge.run!(dry_run: false)
  #
  class MergeEnrollments
    # Data collection stages for intake (1) and exit (3) - these are not moved
    INTAKE_STAGE = 1
    EXIT_STAGE = 3

    attr_reader :enrollment_to_retain, :enrollment_to_destroy, :errors

    def initialize(enrollment_to_retain:, enrollment_to_destroy:)
      @enrollment_to_retain = Hmis::Hud::Enrollment.find(enrollment_to_retain)
      @enrollment_to_destroy = Hmis::Hud::Enrollment.find(enrollment_to_destroy)
      @errors = []
    end

    def run!(dry_run: false)
      validate!
      if dry_run
        print_enrollment_summary
        apply_composite_key_moves(dry_run: true)
        apply_integer_enrollment_id_moves(dry_run: true)
        Rails.logger.info "Would destroy enrollment #{enrollment_to_destroy.id}"
        return
      end
      Hmis::Hud::Enrollment.transaction do
        apply_composite_key_moves(dry_run: false)
        apply_integer_enrollment_id_moves(dry_run: false)
        enrollment_to_destroy.destroy!
      end
      Rails.logger.info "Merged enrollment #{enrollment_to_destroy.id} into enrollment #{enrollment_to_retain.id}"
    end

    def valid?
      validate!(raise_on_error: false)
      errors.empty?
    end

    private

    def validate!(raise_on_error: true)
      @errors = []
      @errors << 'enrollment_to_retain and enrollment_to_destroy must be different enrollments' if enrollment_to_retain.id == enrollment_to_destroy.id
      @errors << 'both enrollments must belong to the same client' unless enrollment_to_retain.client.id.present? && enrollment_to_destroy.client.id.present? && enrollment_to_retain.client.id == enrollment_to_destroy.client.id
      @errors << 'both enrollments must belong to the same HMIS project' unless enrollment_to_retain.project_pk == enrollment_to_destroy.project_pk
      @errors << 'both enrollments must belong to the same HMIS data source' unless enrollment_to_retain.data_source_id == enrollment_to_destroy.data_source_id && ::GrdaWarehouse::DataSource.hmis.exists?(id: enrollment_to_retain.data_source_id)
      raise StandardError, errors.join('; ') if errors.any? && raise_on_error
    end

    def print_enrollment_summary
      [enrollment_to_retain, enrollment_to_destroy].each do |en|
        exit_date = en.exit&.exit_date
        label = en.id == enrollment_to_retain.id ? 'RETAIN' : 'DESTROY'
        Rails.logger.info "[#{label}] Enrollment #{en.id} (#{en.enrollment_id}): entry_date=#{en.entry_date} exit_date=#{exit_date || 'none'}"
      end
    end

    # Only EnrollmentID changes; PersonalID and data_source_id are expected to be the same.
    def composite_assign
      { EnrollmentID: enrollment_to_retain.EnrollmentID }
    end

    def apply_composite_key_moves(dry_run:)
      assign = composite_assign

      # Exit: only move if retain has no exit (there can only be one)
      if enrollment_to_retain.exit.blank? && enrollment_to_destroy.exit.present?
        if dry_run
          Rails.logger.info 'Would move 1 exit to retained enrollment'
        else
          enrollment_to_destroy.exit.update_columns(assign)
        end
      end

      composite_association_names.each do |name|
        scope = enrollment_to_destroy.send(name)
        count = scope.count
        next if count.zero?

        if dry_run
          Rails.logger.info "Would update #{count} #{name} to retained enrollment"
        else
          scope.update_all(assign)
        end
      end

      # Custom assessments: move everything except intake (1) and exit (3)
      scope = enrollment_to_destroy.custom_assessments.where.not(data_collection_stage: [INTAKE_STAGE, EXIT_STAGE])
      count = scope.count
      return unless count.positive?

      if dry_run
        Rails.logger.info "Would update #{count} custom_assessments (non-intake/exit) to retained enrollment"
      else
        scope.update_all(assign)
      end
    end

    def composite_association_names
      [
        :services, :custom_services, :custom_case_notes, :events, :income_benefits, :disabilities, :health_and_dvs, :current_living_situations, :employment_educations, :youth_education_statuses, :assessments, :move_in_addresses
      ]
    end

    def apply_integer_enrollment_id_moves(dry_run:)
      retain_id = enrollment_to_retain.id
      destroy_id = enrollment_to_destroy.id

      integer_moves.each do |model, scope_proc, update_proc|
        scope = scope_proc.call(destroy_id)
        count = scope.count
        next if count.zero?

        if dry_run
          Rails.logger.info "Would update #{count} #{model} to retained enrollment"
        else
          update_proc.call(scope, retain_id)
        end
      end
    end

    def integer_moves
      [
        [
          'Hmis::File',
          ->(id) { Hmis::File.where(enrollment_id: id) },
          ->(scope, retain_id) { scope.update_all(enrollment_id: retain_id) },
        ],
        [
          'Hmis::UnitOccupancy',
          ->(id) { Hmis::UnitOccupancy.where(enrollment_id: id) },
          ->(scope, retain_id) { scope.update_all(enrollment_id: retain_id) },
        ],
        [
          'Hmis::Ce::Referral (source_enrollment_id)',
          ->(id) { Hmis::Ce::Referral.where(source_enrollment_id: id) },
          ->(scope, retain_id) { scope.update_all(source_enrollment_id: retain_id) },
        ],
        [
          'Hmis::Ce::Referral (target_enrollment_id)',
          ->(id) { Hmis::Ce::Referral.where(target_enrollment_id: id) },
          ->(scope, retain_id) { scope.update_all(target_enrollment_id: retain_id) },
        ],
        [
          'HmisExternalApis::ExternalForms::FormSubmission',
          ->(id) { HmisExternalApis::ExternalForms::FormSubmission.where(enrollment_id: id) },
          ->(scope, retain_id) { scope.update_all(enrollment_id: retain_id) },
        ],
      ]
    end
  end
end
