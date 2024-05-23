###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# determine if project is a valid match for a form instance. The match is ranked so that when there are multiple form
# definitions that match a project, we can take the definition with the best rank
#
class Hmis::Form::InstanceProjectMatch
  include Memery
  attr_accessor :project, :instance

  # Match types ordered by rank, from most specific to least specific. Lower rank number if more specific.
  RANKED_MATCHES = [
    PROJECT_MATCH = 'project'.freeze,
    ORGANIZATION_MATCH = 'organization'.freeze,
    PROJECT_TYPE_AND_FUNDER_MATCH = 'project_type_and_funder'.freeze,
    PROJECT_TYPE_MATCH = 'project_type'.freeze,
    PROJECT_FUNDER_MATCH = 'project_funder'.freeze,
    DEFAULT_MATCH = 'default'.freeze,
    DEFAULT_SYSTEM_MATCH = 'default_system'.freeze,
  ].freeze
  MATCH_RANKS = RANKED_MATCHES.each_with_index.to_h.freeze

  def initialize(instance:, project:)
    self.instance = instance
    self.project = project
  end

  def rank
    MATCH_RANKS[match]
  end

  def valid?
    !!match
  end

  protected

  # match to project. Order is significant, should return the best ranked match
  memoize def match
    if instance.entity_type
      case instance.entity_type
      when Hmis::Hud::Project.sti_name
        return instance.entity_id == project.id ? PROJECT_MATCH : nil
      when Hmis::Hud::Organization.sti_name
        return instance.entity_id == project.organization.id ? ORGANIZATION_MATCH : nil
      else
        # entity type is specified but doesn't match
        return nil
      end
    end

    if could_match_project_type? && could_match_funder?
      return matches_project_type? && matches_project_funder? ? PROJECT_TYPE_AND_FUNDER_MATCH : nil
    elsif could_match_project_type?
      return matches_project_type? ? PROJECT_TYPE_MATCH : nil
    elsif could_match_funder?
      return matches_project_funder? ? PROJECT_FUNDER_MATCH : nil
    end

    if matches_default?
      return instance.system? ? DEFAULT_SYSTEM_MATCH : DEFAULT_MATCH
    end

    nil
  end

  def could_match_funder?
    instance.funder.present? || instance.other_funder.present?
  end

  def could_match_project_type?
    instance.project_type.present?
  end

  def matches_default?
    [
      instance.entity_type,
      instance.project_type,
      instance.funder,
      instance.other_funder,
    ].all?(&:blank?)
  end

  def matches_project_type?
    project.project_type && instance.project_type == project.project_type
  end

  def matches_project_funder?
    instance.funder.presence&.in?(project.funders.map(&:funder)) ||
      instance.other_funder.presence&.in?(project.funders.map(&:other_funder))
  end
end
