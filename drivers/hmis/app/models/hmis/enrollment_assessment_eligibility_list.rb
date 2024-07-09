###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

  # @param [Hmis::Hud::Enrollment] enrollment
  def initialize(enrollment:)
    self.client = enrollment.client
    self.project = enrollment.project
    self.enrollment = enrollment
  end

  INTAKE_ROLE = 'INTAKE'.freeze
  UPDATE_ROLE = 'UPDATE'.freeze
  ANNUAL_ROLE = 'ANNUAL'.freeze
  EXIT_ROLE = 'EXIT'.freeze
  POST_EXIT_ROLE = 'POST_EXIT'.freeze
  CUSTOM_ASSESSMENT = 'CUSTOM_ASSESSMENT'.freeze

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
    roles << POST_EXIT_ROLE if assessment_submitted?(EXIT_ROLE) && !assessment_started?(POST_EXIT_ROLE)
    roles << CUSTOM_ASSESSMENT

    filtered_definitions(roles).each do |definition|
      yield(definition)
    end
  end

  protected

  def filtered_definitions(roles)
    fi_t = Hmis::Form::Instance.arel_table
    definitions_by_role = Hmis::Form::Definition.published.
      # skip definition for performance
      exclude_definition_from_select.
      # preload active instances
      includes(:instances).references(fi_t.name).where(fi_t[:active].eq(true)).
      where(role: roles).
      order(version: :desc, id: :desc).
      group_by(&:role)

    roles.flat_map do |role|
      definitions = definitions_by_role[role] || []
      case role
      when CUSTOM_ASSESSMENT
        # allow multiple definitions for this role, return all matches
        definitions.filter do |definition|
          definition.instances.any? { |i| i.project_and_enrollment_match(project: project, enrollment: enrollment) }
        end
      else
        # single definition for this role
        #
        # get the best ranked instance match for this definition
        ranked = definitions.map do |definition|
          rank = definition.project_and_enrollment_match(project: project, enrollment: enrollment)&.rank
          [rank, definition]
        end
        # return best ranked definition
        compacted = ranked.filter { |rank, _| rank.present? }
        # with_index for stable sort
        sorted = compacted.sort_by.with_index { |tuple, idx| [tuple[0], idx] }
        sorted.map(&:last).take(1)
      end
    end
  end

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
