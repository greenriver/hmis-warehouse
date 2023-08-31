###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ProjectProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)

      project = @processor.send(factory_name)

      attributes = case attribute_name
      when 'residential_affiliation_project_ids'
        process_residential_affiliations(value)
      else
        { attribute_name => attribute_value }
      end

      project.assign_attributes(attributes)
    end

    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::Project
    end

    def information_date(_)
    end

    private

    def process_residential_affiliations(value)
      project = @processor.send(factory_name)

      selected_projects_pks = Array.wrap(value).map(&:to_i)
      selected_projects_hud_ids = Hmis::Hud::Project.where(id: selected_projects_pks).pluck(:ProjectID)

      old_affiliations_by_id = project.affiliations.pluck(:id, :res_project_id).to_h
      old_project_hud_ids = old_affiliations_by_id.values

      # ResProjectIDs that we need new Affiliation records for
      res_projects_to_add = (selected_projects_hud_ids - old_project_hud_ids).uniq

      # Primary keys of Affiliation records that should be removed
      affiliations_to_remove = old_affiliations_by_id.reject do |_affiliation_pk, res_project_id|
        selected_projects_hud_ids.include?(res_project_id)
      end.keys.uniq

      {
        affiliations_attributes: [
          *res_projects_to_add.map do |res_project_id|
            {
              res_project_id: res_project_id,
              user: @processor.hud_user,
              **project.slice(:project_id, :data_source_id),
            }
          end,
          *affiliations_to_remove.map { |id| { id: id, _destroy: 1 } },
        ],
      }
    end
  end
end
