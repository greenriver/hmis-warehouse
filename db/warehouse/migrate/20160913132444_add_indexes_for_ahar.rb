class AddIndexesForAhar < ActiveRecord::Migration
  def change
    add_index 'Enrollment', 'ProjectID'
    add_index 'Enrollment', 'ProjectEntryID'
    add_index 'Enrollment', 'EntryDate'

    add_index 'Exit', 'ExitDate'
    add_index 'Exit', 'ProjectEntryID'

    add_index 'Project', 'ProjectID'
    add_index 'Project', 'ProjectType'
  end
end
