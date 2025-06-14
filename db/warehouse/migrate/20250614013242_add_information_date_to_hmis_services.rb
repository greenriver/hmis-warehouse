class AddInformationDateToHmisServices < ActiveRecord::Migration[7.1]
  def change
    update_view 'hmis_services', version: 6, revert_to_version: 5
  end
end
