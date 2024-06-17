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

  def agencies
    {}.tap do |a|
      users.each do |u|
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
      users.each do |u|
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

  private def valid_roles?
    roles_worksheet.cell_at('A2').value == 'Role' && roles_worksheet.cell_at('B1').value == 'Permission'
  end

  private def valid_users?
    users_worksheet.cell_at('A1').value == 'First Name' && users_worksheet.cell_at('B1').value == 'Last Name'
  end

  private def existing_role(role_name)
    existing_roles[role_name]
  end

  private def existing_roles
    @existing_roles ||= Role.editable.index_by(&:name)
  end
end
