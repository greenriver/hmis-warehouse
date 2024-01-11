###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ==  Hmis::ClientAssessmentEligibilityList
#
# Given a client, a project, and an optional enrollment, return a collection of assessments
#
class Hmis::ClientAssessmentEligibilityList
  include Enumerable
  attr_accessor :client, :project, :enrollment

  def initialize(client:, project:, enrollment: nil)
    self.client = client
    self.project = project
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
    roles << INTAKE_ROLE unless assessed?(INTAKE_ROLE)

    # Exit/Update/Annual can only be added to open enrollment
    roles += [EXIT_ROLE, UPDATE_ROLE, ANNUAL_ROLE] unless assessed?(EXIT_ROLE)
    roles << POST_EXIT_ROLE if assessed?(EXIT_ROLE) && !assessed?(POST_EXIT_ROLE) && enrollment&.head_of_household?

    # FIXME: this could be one query rather than ~25 queries :(
    roles.each do |role|
      definition = Hmis::Form::Definition.for_project(project: project, role: role).first
      yield(definition) if definition
    end
  end

  protected

  def assessed?(role)
    data_collection_stage = DATA_COLLECTION_STAGE_BY_ROLE.fetch(role)
    @assessed_stages ||= client.custom_assessments.
      where(enrollment_id: enrollment.enrollment_id).
      pluck(Hmis::Hud::CustomAssessment.arel_table[:data_collection_stage]).
      to_set
    @assessed_stages.include?(data_collection_stage)
  end
end
