# frozen_string_literal: true

class AddPrintCaseNotesPerm < ActiveRecord::Migration[7.1]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
  end

  def down
    remove_column :hmis_roles, :can_print_client_case_notes
  end
end
