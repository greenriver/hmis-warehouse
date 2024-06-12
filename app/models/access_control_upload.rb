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
