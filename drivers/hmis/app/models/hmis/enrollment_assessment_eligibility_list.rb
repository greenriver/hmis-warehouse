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

  # @param [Hmis::Hud::Enrollment] enrollment
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
    roles << POST_EXIT_ROLE if assessment_submitted?(EXIT_ROLE) && !assessment_started?(POST_EXIT_ROLE) && enrollment.head_of_household?
    roles << CUSTOM_ASSESSMENT

    filtered_definitions(roles).each do |definition|
      yield(definition)
    end
  end

  protected

  PRIORITY_MATCHES = [
    PROJECT_MATCH = 'project'.freeze,
    ORGANIZATION_MATCH = 'organization'.freeze,
    PROJECT_TYPE_AND_FUNDER_MATCH = 'project_type_and_funder'.freeze,
    PROJECT_TYPE_MATCH = 'project_type'.freeze,
    PROJECT_FUNDER_MATCH = 'project_funder'.freeze,
    DEFAULT_MATCH = 'default'.freeze,
  ].freeze

  # group definitions by match
  def definitions_by_match(definitions)
    results = {}
    definitions.group_by do |definition|
      found_matches = definition.instances.map do |instance|
        if instance.entity_type
          case instance.entity_type
          when Hmis::Hud::Project.sti_name
            next PROJECT_MATCH if instance.entity_id == project.id
          when Hmis::Hud::Organization.sti_name
            next ORGANIZATION_MATCH if instance.entity_id == project.organization.id
          else
            # entity type is specified but doesn't match project
            next
          end
        end

        if instance.project_type
          if project.project_type && instance.project_type == project.project_type
            next PROJECT_TYPE_AND_FUNDER_MATCH if instance.funder.in?(project.funders.map(&:funder))
            next PROJECT_TYPE_MATCH unless instance.funder
          end
        else
          next PROJECT_FUNDER_MATCH if instance.funder.in?(project.funders.map(&:funder))
        end

        next DEFAULT_MATCH unless instance.entity_type || instance.project_type || instance.funder || instance.other_funder
      end
      next if found_matches.empty?

      # the highest priority match
      best_match = PRIORITY_MATCHES.detect { |match| match.in?(found_matches) }
      results[best_match] ||= []
      results[best_match].push(definition)
    end
    results
  end

  def filtered_definitions(roles)
    definitions = Hmis::Form::Definition.
      exclude_definition_from_select. # for performance
      where(role: roles).
      preload(:instances)
    # {'project' => [Definition, ...]}
    matches = definitions_by_match(definitions)

    results = roles.flat_map do |role|
      case role
      when CUSTOM_ASSESSMENT
        # multiple definitions for this role
        # all definitions with this role
        matches.values.flatten&.filter { |definition| definition.role == role }
      else
        # single definition for this role
        # find the best match based on match_type for this role
        PRIORITY_MATCHES.map do |match|
          matches[match]&.detect { |definition| definition.role == role }
        end.compact
      end
    end
    results
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
