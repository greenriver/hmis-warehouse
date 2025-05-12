class AddDbConstraints < ActiveRecord::Migration[7.0]
  def up
    [
      ['Enrollment', 'PersonalID'],
      ['Enrollment', 'EnrollmentID'],
      ['Enrollment', 'EntryDate'],
      ['Enrollment', 'data_source_id'],
      ['Exit', 'ExitID'],
      ['Exit', 'ExitDate'],
      ['Client', 'PersonalID'],
      ['Client', 'data_source_id'],
    ].each do |table, column|
      add_check_constraint table, "\"#{column}\" IS NOT NULL", name: "#{table.downcase}_#{column.downcase}_not_null", validate: false
    end
  end
end
