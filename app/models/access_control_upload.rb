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
      new_role = new_role?(row.cells.first.value)
      OpenStruct.new(name: name, new_role: new_role)
    end.compact
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

  private def new_role?(role_name)
    existing_role_names.include?(role_name)
  end

  private def existing_role_names
    @existing_role_names ||= Role.pluck(:name)
  end
end
