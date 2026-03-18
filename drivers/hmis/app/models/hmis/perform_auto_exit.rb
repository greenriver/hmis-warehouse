###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared service that performs an exit for one or more HMIS enrollments. Callers supply
# enrollment_id, exit_date, and options; this class creates the records and runs side effects.
#
# What it does (per enrollment)
# - Creates Hmis::Hud::Exit (default destination "No exit interview completed"; optional auto_exited timestamp).
# - Creates an Exit Assessment. (Note: it does not generate associated records such as IncomeBenefit, see #8920)
# - Releases any assigned unit and closes any external legacy referral.
#
# Options
# - exit_household_members: when true, exits all open enrollments in the same household (same exit_date).
# - acting_user_id: nil => system user; otherwise the Hmis::User who is acting.
# - exit_destination: nil => default "No exit interview completed".
# - auto_exited: optional DateTime (e.g. from Auto Exit Job); when set, stored on Exit.auto_exited.
#
# Used by: Hmis::AutoExitJob, HmisExternalApis::AcHmis::BulkVoider, and bulk-exit flows (e.g. #6917).
#
# @example Single enrollment
#   Hmis::PerformAutoExit.call(enrollment_id: enrollment.id, exit_date: Date.current)
#
# @example Whole household with auto_exited timestamp (e.g. from Auto Exit Job)
#   Hmis::PerformAutoExit.call(
#     enrollment_id: enrollment.id,
#     exit_date: Date.current,
#     exit_household_members: true,
#     auto_exited: DateTime.current,
#   )
#
# @example With acting user and custom destination
#   Hmis::PerformAutoExit.call(
#     enrollment_id: enrollment.id,
#     exit_date: Date.current,
#     acting_user_id: current_user.id,
#     exit_destination: 99,
#   )
#
class Hmis::PerformAutoExit
  def self.call(**args)
    new(**args).call
  end

  def initialize(
    enrollment_id:,
    exit_date:,
    exit_household_members: true, # Whether to exit the entire household
    acting_user_id: nil, # User to act as for the exit (defaults to system user)
    exit_destination: nil, # Destination for the exit (defaults to "No exit interview completed")
    auto_exited: nil # Optional; when set (e.g. DateTime.current), Exit.auto_exited is set
  )
    @enrollment_id = enrollment_id
    @exit_date = exit_date
    @exit_household_members = exit_household_members
    @acting_user_id = acting_user_id
    @exit_destination = exit_destination
    @auto_exited = auto_exited
  end

  def call
    base_scope = if @exit_household_members
      Hmis::Hud::Enrollment.find(@enrollment_id).household.enrollments
    else
      Hmis::Hud::Enrollment.where(id: @enrollment_id)
    end
    # Drop exited and WIP enrollments
    enrollments_to_exit = base_scope.open_excluding_wip
    # Return early if nothing to exit. Idempotent behavior (e.g. BulkVoider may call for same household twice)
    return if enrollments_to_exit.empty?

    raise 'PerformAutoExit invoked on non-HMIS enrollments' unless enrollments_to_exit.map(&:data_source).uniq.all?(&:hmis?)

    Hmis::Hud::Base.transaction do
      enrollments_to_exit.each do |e|
        perform_exit(e)
      end
    end
  end

  private

  def perform_exit(enrollment)
    destination = @exit_destination.presence || ::HudHelper.util.destination_no_exit_interview_completed
    exit_record = Hmis::Hud::Exit.new(
      personal_id: enrollment.personal_id,
      enrollment_id: enrollment.enrollment_id,
      data_source_id: enrollment.data_source_id,
      user_id: acting_hud_user.user_id,
      exit_date: @exit_date,
      destination: destination,
    )
    exit_record.auto_exited = @auto_exited if @auto_exited.present?

    exit_assessment = Hmis::Hud::CustomAssessment.new(
      user_id: acting_hud_user.user_id,
      assessment_date: @exit_date,
      data_collection_stage: 3,
      data_source_id: enrollment.data_source_id,
      personal_id: enrollment.personal_id,
      enrollment_id: enrollment.enrollment_id,
    )
    exit_assessment.created_by_hud_user = acting_hud_user
    exit_assessment.updated_by_hud_user = acting_hud_user
    exit_assessment.build_form_processor(exit: exit_record)

    raise ActiveRecord::RecordInvalid, exit_record if exit_record.invalid?

    exit_assessment.save!

    enrollment.release_unit!(@exit_date, user: acting_app_user)
    enrollment.close_referral!(current_user: acting_app_user)
  end

  def data_source
    @data_source ||= Hmis::Hud::Enrollment.find_by(id: @enrollment_id).data_source
  end

  def acting_app_user
    @acting_app_user ||= if @acting_user_id.present?
      Hmis::User.find(@acting_user_id).tap { |u| u.hmis_data_source_id = data_source.id }
    else
      Hmis::User.system_user.tap { |u| u.hmis_data_source_id = data_source.id }
    end
  end

  def acting_hud_user
    @acting_hud_user ||= Hmis::Hud::User.from_user(acting_app_user)
  end
end
