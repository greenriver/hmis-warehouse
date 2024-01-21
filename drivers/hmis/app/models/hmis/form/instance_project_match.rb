###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::InstanceProjectMatch
  include Memery
  attr_accessor :project, :instance

  # match types ordered by rank. Lower rank is better
  RANKED_MATCHES = [
    PROJECT_MATCH = 'project'.freeze,
    ORGANIZATION_MATCH = 'organization'.freeze,
    PROJECT_TYPE_AND_FUNDER_MATCH = 'project_type_and_funder'.freeze,
    PROJECT_TYPE_MATCH = 'project_type'.freeze,
    PROJECT_FUNDER_MATCH = 'project_funder'.freeze,
    DEFAULT_MATCH = 'default'.freeze,
  ].freeze
  MATCH_RANKS = RANKED_MATCHES.each_with_index.to_h.freeze

  def initialize(instance:, project:)
    self.instance = instance
    self.project = project
  end

  def rank
    MATCH_RANKS[match]
  end

  # match to project. Order is significant, should return the best ranked match
  memoize def match
    if instance.entity_type
      case instance.entity_type
      when Hmis::Hud::Project.sti_name
        return PROJECT_MATCH if instance.entity_id == project.id
      when Hmis::Hud::Organization.sti_name
        return ORGANIZATION_MATCH if instance.entity_id == project.organization.id
      else
        # entity type is specified but doesn't match
        return
      end
    end

    if instance.project_type
      if project.project_type && instance.project_type == project.project_type
        return PROJECT_TYPE_AND_FUNDER_MATCH if instance.funder.in?(project.funders.map(&:funder))
        return PROJECT_TYPE_MATCH unless instance.funder
      end
    elsif instance.funder.in?(project.funders.map(&:funder))
      return PROJECT_FUNDER_MATCH
    end

    return DEFAULT_MATCH unless instance.entity_type || instance.project_type || instance.funder || instance.other_funder
  end
end
