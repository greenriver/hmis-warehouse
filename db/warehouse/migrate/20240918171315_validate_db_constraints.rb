class ValidateDbConstraints < ActiveRecord::Migration[7.0]
  def up
    tables.each do |table, column|
      safety_assured do
        validate_check_constraint table, name: "#{table.downcase}_#{column.downcase}_not_null"
      end
      change_column_null table, column, false
      safety_assured do
        remove_check_constraint table, name: "#{table.downcase}_#{column.downcase}_not_null"
      end
    end
  end

  def down
    tables.each do |table, column|
      change_column_null table, column, true
    end
  end

  def tables
    [
      ['Enrollment', 'PersonalID'],
      ['Enrollment', 'EnrollmentID'],
      ['Enrollment', 'EntryDate'],
      ['Enrollment', 'data_source_id'],
      ['Exit', 'ExitID'],
      ['Exit', 'ExitDate'],
      ['Client', 'PersonalID'],
      ['Client', 'data_source_id'],
    ]
  end
end
