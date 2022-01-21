class AddValidUnpayableReasonToQa < ActiveRecord::Migration[5.2]
  def change
    add_column :qualifying_activities, :valid_unpayable_reasons, :string, array: true
  end
end
