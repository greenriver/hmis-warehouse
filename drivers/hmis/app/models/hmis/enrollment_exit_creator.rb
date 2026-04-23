###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared service that performs an exit for one or more HMIS enrollments. Callers supply
# enrollment_id, exit_date, and options; this class creates the records and runs side effects.
#
# Used by: Hmis::AutoExitJob, HmisExternalApis::AcHmis::BulkVoider, and bulk-exit flows (e.g. #6917).
# This is not used as part of typical application enrollment workflows (where exit is handled by exit assessment submission).
#
# Validation
# - This class does NOT enforce extra business rules beyond what the Exit model validates.
# (For example, it does not require that HoH exits first, or that ExitDate falls within the
# project operating period). Callers are responsible for passing a valid `exit_date`.
# - Raises `Cannot exit incomplete enrollments` if `exit_household_members` is true and any
#   household member has an incomplete (WIP) enrollment, or if the single enrollment being
#   exited is incomplete—partial household exit is not supported.
#
# What it does (per enrollment)
# - Creates Hmis::Hud::Exit (default destination "No exit interview completed"; optional auto_exited timestamp).
# - Creates an Exit Assessment. (Note: it does not generate associated records such as IncomeBenefit, see #8920)
# - Releases any assigned unit and closes any external legacy referral.
#
# Options
# - exit_household_members: when true, exits all open enrollments in the same household (same exit_date).
# - exit_destination: HUD Exit Destination code, defaults to "No exit interview completed"
# - acting_user_id: application user to record as the actor (Defaults to System User)
# - auto_exited: optional DateTime (e.g. from Auto Exit Job); when set, stored on Exit.auto_exited.
class Hmis::EnrollmentExitCreator
  def self.call(**args)
    new(**args).call
  end

  def initialize(
    enrollment_id:,
    exit_date:,
    exit_household_members: false, # Whether to exit the entire household
    exit_destination: ::HudHelper.util.destination_no_exit_interview_completed,
    acting_user_id: nil, # Optional actor, defaults to System User
    auto_exited: nil # Optional timestamp to store on `Exit.auto_exited`
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
    # Raise if any enrollments are incomplete (WIP or not in progress), we shouldn't auto-exit those and we don't want to exit other members of the household and leave them dangling.
    raise 'Cannot exit incomplete enrollments' if base_scope.in_progress.exists?

    # Drop exited and WIP enrollments
    enrollments_to_exit = base_scope.open_excluding_wip
    # Return early if nothing to exit. Idempotent behavior (e.g. BulkVoider may call for same household twice)
    return if enrollments_to_exit.empty?

    raise "#{self.class.name} invoked on non-HMIS enrollments" unless enrollments_to_exit.map(&:data_source).uniq.all?(&:hmis?)

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
    enrollment.close_referral!(current_user: acting_app_user) # close legacy referral. doesn't do anything for CE referrals
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
