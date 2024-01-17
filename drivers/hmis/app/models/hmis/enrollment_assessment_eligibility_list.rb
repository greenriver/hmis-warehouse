###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ==  Hmis::EnrollmentAssessmentEligibilityList
#
# return a collection of assessments for the given enrollment
#
class Hmis::EnrollmentAssessmentEligibilityList
  include Enumerable
  attr_accessor :client, :project, :enrollment

  # @param enrollment [Hmis::Hud::Enrollment]
  def initialize(enrollment:)
    self.client = enrollment.client
    self.project = enrollment.project
    self.enrollment = enrollment
  end

  INTAKE_ROLE = 'INTAKE'.freeze
  UPDATE_ROLE = 'UPDATE '.freeze
  ANNUAL_ROLE = 'ANNUAL'.freeze
  EXIT_ROLE = 'EXIT'.freeze
  POST_EXIT_ROLE = 'POST_EXIT'.freeze

  DATA_COLLECTION_STAGE_BY_ROLE = {
    INTAKE_ROLE => 1,
    UPDATE_ROLE => 2,
    EXIT_ROLE => 3,
    ANNUAL_ROLE => 5,
    POST_EXIT_ROLE => 6,
  }.freeze

  def each
    roles = []
    # Show "intake" item even if the client is entered but does not have an intake
    roles << INTAKE_ROLE unless assessment_started?(INTAKE_ROLE)

    # Exit/Update/Annual can only be added to open enrollment
    roles << EXIT_ROLE unless assessment_started?(EXIT_ROLE)
    roles += [UPDATE_ROLE, ANNUAL_ROLE] unless assessment_submitted?(EXIT_ROLE)
    roles << POST_EXIT_ROLE if assessment_submitted?(EXIT_ROLE) && !assessment_started?(POST_EXIT_ROLE) && enrollment.head_of_household?

    # FIXME: this could be one query rather than ~25 queries :(
    roles.each do |role|
      Hmis::Form::Definition.for_project(project: project, role: role).each do |definition|
        yield(definition)
      end
    end
    # FIXME this isn't quite right, should filter by project
    Hmis::Form::Definition.where(role: 'CUSTOM_ASSESSMENT').each do |definition|
      yield(definition)
    end
  end

  protected

  def role_id(role)
    DATA_COLLECTION_STAGE_BY_ROLE.fetch(role)
  end

  def assessment_started?(role)
    assessed_stages.any? { |stage, _| stage == role_id(role) }
  end

  def assessment_submitted?(role)
    assessed_stages.any? { |stage, wip| stage == role_id(role) && !wip }
  end

  def assessed_stages
    cas_t = Hmis::Hud::CustomAssessment.arel_table
    @assessed_stages ||= client.custom_assessments.
      where(enrollment_id: enrollment.enrollment_id).
      pluck(cas_t[:data_collection_stage], cas_t[:wip])
  end
end
