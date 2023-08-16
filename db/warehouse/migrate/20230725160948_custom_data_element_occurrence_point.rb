class CustomDataElementOccurrencePoint < ActiveRecord::Migration[6.1]
  def change
    # add flag to indicate whether the element should be collectable "at occurrence"
    # this only really applies to elements that are tied to an Enrollment
    add_column :CustomDataElementDefinitions, :at_occurrence, :boolean, default: :false, null: false
  end
end
