class AddShapeData < ActiveRecord::Migration[5.2]
  def change
    # remove them all on up and down
    GrdaWarehouse::Shape::ZipCode.delete_all
    GrdaWarehouse::Shape::CoC.delete_all

    reversible do |r|
      r.up do
        Rake::Task['grda_warehouse:get_shapes'].invoke

        url = 'warehouse_reports/overlapping_coc_utilization'
        r = GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).first_or_initialize
        r.report_group = 'Operational Reports'
        r.name = 'Overlapping CoC Utilization'
        r.description = 'Overlapping CoC utilization'
        r.limitable = true
        r.save!
      end
    end
  end
end
