###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientHistory::EnrollmentView
  attr_reader :user

  # @param user [User] viewer; affiliated project names are resolved with this user's permissions
  def initialize(user:)
    @user = user
  end

  # @param enrollment [Hash] a rollup row with :ProjectID and :data_source_id
  def program_tooltip_data_for_enrollment(enrollment)
    key = [enrollment[:ProjectID], enrollment[:data_source_id]]
    affiliated_projects_str = affiliated_str(affiliated_projects[key])
    residential_projects_str = affiliated_str(affiliated_residential_projects[key])
    # only show tooltip if there are projects to list
    if affiliated_projects_str.present? || residential_projects_str.present?
      title = [affiliated_projects_str, residential_projects_str].compact.join("\n")
      {
        'bs-toggle' => :tooltip,
        title: title,
      }
    else
      {}
    end
  end

  private def affiliated_str(project_names)
    return nil if project_names.blank?

    "Affiliated with #{project_names.to_sentence}"
  end

  # Residential project names keyed by the services project they are affiliated with.
  private def affiliated_residential_projects
    @affiliated_residential_projects ||= affiliation_rows.each_with_object(Hash.new { |h, k| h[k] = [] }) do |row, index|
      project_id, res_project_id, ds_id = row
      residential_project = projects_by_key[[res_project_id, ds_id]]
      index[[project_id, ds_id]] << residential_project&.name(user)
    end
  end

  # Services project names keyed by the residential project they are affiliated with.
  private def affiliated_projects
    @affiliated_projects ||= affiliation_rows.each_with_object(Hash.new { |h, k| h[k] = [] }) do |row, index|
      project_id, res_project_id, ds_id = row
      project = projects_by_key[[project_id, ds_id]]
      index[[res_project_id, ds_id]] << project&.name(user)
    end
  end

  # `[ProjectID, ResProjectID, data_source_id]` triples. Plucked instead of preloaded because
  # :project and :residential_project both point at Project via composite keys declared in a
  # different column order, which confuses ActiveRecord's association preloader into resolving
  # both to the same row.
  private def affiliation_rows
    @affiliation_rows ||= GrdaWarehouse::Hud::Affiliation.pluck(:ProjectID, :ResProjectID, :data_source_id)
  end

  private def projects_by_key
    @projects_by_key ||= begin
      keys = affiliation_rows.flat_map { |project_id, res_project_id, ds_id| [[project_id, ds_id], [res_project_id, ds_id]] }.uniq
      if keys.empty?
        {}
      else
        p_t = GrdaWarehouse::Hud::Project.arel_table
        where_clause = keys.map { |project_id, ds_id| p_t[:ProjectID].eq(project_id).and(p_t[:data_source_id].eq(ds_id)) }.inject(:or)
        GrdaWarehouse::Hud::Project.where(where_clause).index_by { |project| [project.ProjectID, project.data_source_id] }
      end
    end
  end
end
