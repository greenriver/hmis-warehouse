class AddUniqueConstraintTobCustomRows < ActiveRecord::Migration[6.1]
  def up
    # Remove duplicates
    remove = []
    CustomImportsBostonService::Row.order(import_file_id: :desc).
      pluck(:service_id, :import_file_id, :id).
      group_by(&:shift).each do |service_id, data|
        next unless data.count > 1

        # The first row will be part of the newest import file, data is [[import_file_id, id]]
        remove += data.drop(1).map(&:last)
      end
    remove.each_slice(10_000) do |ids|
      CustomImportsBostonService::Row.where(id: ids).delete_all
    end
    add_index :custom_imports_b_services_rows, :service_id, unique: true
  end
end
