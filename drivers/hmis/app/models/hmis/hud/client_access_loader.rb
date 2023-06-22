###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::ClientAccessLoader < Hmis::BaseAccessLoader
  def fetch(items)
    resolved = {}

    client_ids = items.map { |a| a.first.id }

    access_groups_by_client_id = Hmis::Hud::Project
      .joins(:client, :group_viewable_entities)
      .where('Client.id in ?', client_ids)
      .select('Client.id, group_viewable_entities.access_group_id')

    # user roles by access group id
    roles_by_access_group_id = user.roles.group_by('access_groups.id')

    roles_by_group_id = Hmis::Role
      .joins(project: :client)
      .where('Client.id in ?', client_ids - resolved.keys)
      .group('Client.id')

    items.each do |item|
      client, permission_method = item

      access_groups = access_groups_by_client_id[client.id]
      next if access_groups.blank?

      roles = access_groups.map { |g| roles_by_group_id[g.id] }.compact

      resolved[client.id] = roles.any? do |role|
        role[permission_method]
      end
    end

    client_ids.map { |id| !!resolved[id] }
  end

    # enrollments_by_client = Hmis::Hud::Client.joins(:enrollments)
    #   .group('Client.id')
    #   .where(id: client_ids)

    # items.each do |item|
    #   client, permission_method = item

    #   if user.send(permission_method)
    #     enrollments = enrollments_by_client[client.id]
    #     # clients that have no enrollments have global access
    #     resolved[client.id] = true if enrollments.empty?
    #   else
    #     resolved[client.id] = false
    #   end
    # end

    # projects = Hmis::Hud::Project.joins(:client)
    # projects = Hmis::Wip.enrollments.where(client: client_ids).select()to_sql
    # access_group_ids = Hmis::GroupViewableEntity.includes_entities(projects).pluck(:access_group_id)

  #def get_projects_by_client_id(client_ids)

  #  #wip_enrollment_projects = Hmis::Wip.enrollments
  #  #  .where(client_id: client_ids)
  #  #  .pluck(:project_id, :client_id)

  #  #@Hmis::Hud::Project.joins(:client)
  #  #@  .where('Client.id in ?', client_ids)
  #  #@  .group('Client.id')
  #end

end
