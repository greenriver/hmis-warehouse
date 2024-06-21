###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rubyXL'
class AccessControlUpload < ApplicationRecord
  has_one_attached :file
  belongs_to :user

  def valid_import?
    valid_roles? && valid_users?
  end

  def roles
    roles_worksheet.map do |row|
      # First two rows are headers
      next unless row.index_in_collection > 1

      name = row.cells.first.value
      existing_role = existing_role(name)
      OpenStruct.new(
        name: name,
        new_role: existing_role.blank?,
        permissions: permissions_for_row(row, existing_role),
      )
    end.compact
  end

  def users
    user_data.map do |user|
      OpenStruct.new(
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        agency: user.agency,
        existing_user_id: user.existing_user_id,
      )
    end.uniq.compact
  end

  def collections
    {}.tap do |col|
      collections_worksheet.each do |row|
        # First row is headers
        next unless row.index_in_collection.positive?
        # Skip any collections with no name
        next unless row.cells[0].value.present?

        name = row.cells.first.value
        existing_collection = existing_collection(name)
        col[name] ||= OpenStruct.new(
          name: name,
          new_collection: existing_collection.blank?,
        )

        collection_relations.each.with_index do |(relation, existing_method), i|
          col[name][relation] ||= []
          column_number = i + 1
          item_name = row.cells[column_number]&.value
          next unless item_name.present?

          col[name].send(relation) << OpenStruct.new(
            name: item_name,
            found: send(existing_method).include?(item_name),
          )
        end
      end
    end.values
  end

  def access_controls
    Set.new.tap do |acls|
      users_worksheet.each do |row|
        # First row is headers
        next unless row.index_in_collection.positive?

        # NOTE: order based on template
        role_name = row.cells[4].value
        user_group_name = row.cells[5].value
        collection_name = row.cells[6].value
        next unless role_name && user_group_name && collection_name

        existing_acl = existing_acls.include?([role_name, user_group_name, collection_name])
        acls << OpenStruct.new(
          role: role_name,
          user_group: user_group_name,
          collection: collection_name,
          new_access_control: existing_acl.blank?,
        )
      end
    end
  end

  private def user_data
    users_worksheet.map do |row|
      # First row is headers
      next unless row.index_in_collection.positive?

      # NOTE: order based on template
      email = row.cells[2].value
      OpenStruct.new(
        first_name: row.cells[0].value,
        last_name: row.cells[1].value,
        email: email,
        agency: row.cells[3].value,
        user_group: row.cells[5].value,
        existing_user_id: User.find_by(email: email)&.id,
      )
    end.uniq.compact
  end

  # NOTE: order based on template
  def collection_relations
    {
      data_sources: :existing_data_sources,
      organizations: :existing_organizations,
      project: :existing_projects,
      project_groups_for_projects: :existing_project_groups,
      cocs: :existing_cocs,
      cohorts: :existing_cohorts,
      reports: :existing_reports,
      project_groups_for_project_groups: :existing_project_groups,
    }
  end

  def agencies
    {}.tap do |a|
      user_data.each do |u|
        a[u.agency] ||= OpenStruct.new(
          existing_agency_id: Agency.find_by(name: u.agency)&.id,
        )
        a[u.agency].users ||= []
        a[u.agency].users << u.email
      end
    end
  end

  def user_groups
    {}.tap do |a|
      user_data.each do |u|
        a[u.user_group] ||= OpenStruct.new(
          existing_user_group_id: UserGroup.find_by(name: u.user_group)&.id,
        )
        a[u.user_group].users ||= []
        a[u.user_group].users << u.email
      end
    end
  end

  private def titles
    @titles ||= [].tap do |h|
      Role.permissions(exclude_health: true).count.times do |i|
        title = roles_worksheet[1][2 + i]&.value
        h << title if title.present?
      end
    end
  end

  private def permissions_for_row(row, existing_role)
    {}.tap do |p|
      Role.permissions(exclude_health: true).count.times do |i|
        title = titles[i]
        value = case row[2 + i]&.value
        when 'X', 'x', 'Y', 'y', 'TRUE', 'true'
          true
        else
          false
        end
        perm = Role.permission_from_title(title)
        next unless perm

        p[perm[:column]] = {
          title: title,
          existing_value: existing_role.try(:[], perm[:column]),
          incoming_value: value,
        }
      end
    end
  end

  private def workbook
    @workbook ||= ::RubyXL::Parser.parse_buffer(file.download)
  end

  private def roles_worksheet
    workbook['Roles']
  end

  private def users_worksheet
    workbook['Users']
  end

  private def collections_worksheet
    workbook['Collections']
  end

  private def valid_roles?
    roles_worksheet.cell_at('A2').value == 'Role' && roles_worksheet.cell_at('B1').value == 'Permission'
  end

  private def valid_users?
    users_worksheet.cell_at('A1').value == 'First Name' && users_worksheet.cell_at('B1').value == 'Last Name'
  end

  private def collections_valid?
    collections_worksheet.cell_at('A1').value == 'Collection' && collections_worksheet.cell_at('B1').value == 'Data Sources'
  end

  private def existing_role(role_name)
    existing_roles[role_name]
  end

  private def existing_roles
    @existing_roles ||= Role.editable.index_by(&:name)
  end

  private def existing_collection(collection_name)
    existing_collections[collection_name]
  end

  private def existing_collections
    @existing_collections ||= Collection.general.index_by(&:name)
  end

  private def existing_data_sources
    @existing_data_sources ||= GrdaWarehouse::DataSource.pluck(:name).to_set
  end

  private def existing_organizations
    @existing_organizations ||= GrdaWarehouse::Hud::Organization.pluck(:name).to_set
  end

  private def existing_projects
    @existing_projects ||= GrdaWarehouse::Hud::Project.pluck(:name).to_set
  end

  private def existing_project_groups
    @existing_project_groups ||= GrdaWarehouse::ProjectGroup.pluck(:name).to_set
  end

  private def existing_cohorts
    @existing_cohorts ||= GrdaWarehouse::Cohort.pluck(:name).to_set
  end

  private def existing_reports
    @existing_reports ||= GrdaWarehouse::WarehouseReports::ReportDefinition.pluck(:name).to_set
  end

  private def existing_cocs
    @existing_cocs ||= GrdaWarehouse::Hud::ProjectCoc.pluck(:coc_code).to_set
  end

  private def existing_acls
    r_t = Role.arel_table
    ug_t = UserGroup.arel_table
    c_t = Collection.arel_table
    @existing_acls ||= AccessControl.
      joins(:role, :user_group, :collection).
      pluck(r_t[:name], ug_t[:name], c_t[:name]).
      to_set
  end
end
