class RenameSpmMeasureTwoTable < ActiveRecord::Migration[6.1]
  def up
    ri_t = HudReports::ReportInstance.arel_table

    # Rename the table name in the cells
    HudReports::ReportCell.
      joins(:report_instance).
      where(question: '2').
      where(ri_t[:report_name].eq('System Performance Measures - FY 2023')).
      update_all(question: '2a and 2b')

    # Update the metadata to have the correct table name
    HudReports::ReportCell.
      joins(:report_instance).
      where(question: 'Measure 2').
      where(ri_t[:report_name].eq('System Performance Measures - FY 2023')).
      update_all(metadata: {"tables"=>["2a and 2b"]})
  end
end
