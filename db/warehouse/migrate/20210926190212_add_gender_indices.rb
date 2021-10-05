class AddGenderIndices < ActiveRecord::Migration[5.2]
  def change
    add_index :Client, :Female
    add_index :Client, :Male
    add_index :Client, :NoSingleGender
    add_index :Client, :Transgender
    add_index :Client, :Questioning
    add_index :Client, :GenderNone
  end
end
