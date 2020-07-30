class AllowsNullInDeprecatedOtherAgencyInvolvementColumn < ActiveRecord::Migration[5.2]
  def change
    change_column_null :youth_intakes, :other_agency_involvement, true
  end
end
