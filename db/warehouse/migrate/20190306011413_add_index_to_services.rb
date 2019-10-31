class AddIndexToServices < ActiveRecord::Migration[4.2]
  def tables
    [
      'Affiliation',
      'Disabilities',
      'EmploymentEducation',
      'EnrollmentCoC',
      'Exit',
      'Export',
      'Funder',
      'HealthAndDV',
      'IncomeBenefits',
      'Inventory',
      'Organization',
      'Project',
      'ProjectCoC',
      'Services',
      'Geography',
    ]
  end

  def up
    tables.each do |t|
      unless index_exists?(t, ["data_source_id", "#{t}ID"], name: "unk_#{t}")
        add_index t, ["data_source_id", "#{t}ID"], name: "unk_#{t}", unique: true, using: :btree 
      end
    end
    t = 'Enrollment'
    unless index_exists?(t, ["data_source_id", "#{t}ID", "PersonalID"], name: "unk_#{t}")
      add_index t, ["data_source_id", "#{t}ID", "PersonalID"], name: "unk_#{t}", unique: true, using: :btree 
    end
  end

  def down
    tables.each do |t|
      if index_exists?(t, ["data_source_id", "#{t}ID"], name: "unk_#{t}")
        remove_index t, column: ["data_source_id", "#{t}ID"], name: "unk_#{t}"
      end
    end
    t = 'Enrollment'
    if index_exists?(t, ["data_source_id", "#{t}ID", "PersonalID"], name: "unk_#{t}")
      remove_index t, column: ["data_source_id", "#{t}ID", "PersonalID"], name: "unk_#{t}"
    end
  end
end