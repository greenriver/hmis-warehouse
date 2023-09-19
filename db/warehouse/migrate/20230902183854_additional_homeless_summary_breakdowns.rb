class AdditionalHomelessSummaryBreakdowns < ActiveRecord::Migration[6.1]
  def change
    [
      :spm_all_persons,
      :spm_without_children,
      :spm_with_children,
      :spm_only_children,
      :spm_without_children_and_fifty_five_plus,
      :spm_adults_with_children_where_parenting_adult_18_to_24,
    ].each do |slug|
      col = "#{slug}__mid_east_n_african"[0..62]
      add_column :homeless_summary_report_clients, col, :integer unless column_exists?(:homeless_summary_report_clients, col)
      col = "#{slug}__hispanic_latinaeo"[0..62]
      add_column :homeless_summary_report_clients, "#{slug}__hispanic_latinaeo", :integer unless column_exists?(:homeless_summary_report_clients, col)
    end
  end
end
