class SetConfidentialFileNullP1 < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::File.with_deleted.where(confidential: nil).update_all(confidential: false)
  end
end
