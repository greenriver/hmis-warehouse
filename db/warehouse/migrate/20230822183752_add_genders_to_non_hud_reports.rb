class AddGendersToNonHudReports < ActiveRecord::Migration[6.1]
  def change
    [
      :woman,
      :man,
      :culturally_specific,
      :different_identity,
      :non_binary,
      :hispanic_latinaeo,
      :mid_east_n_african,
    ].each do |col|
      add_column :hmis_dqt_clients, col, :integer
      add_column :system_pathways_clients, col, :boolean
      add_column :ma_monthly_performance_enrollments, col, :boolean
    end
    [
      :hispanic_latinaeo,
      :mid_east_n_african,
    ].each do |col|
      add_column :hmis_dqt_clients, "spm_#{col}", :integer
      add_column :hmis_dqt_clients, "_all_persons__#{col}", :integer
      add_column :hmis_dqt_clients, "spm_with_children__#{col}", :integer
      add_column :hmis_dqt_clients, "spm_only_children__#{col}", :integer
      add_column :hmis_dqt_clients, "spm_without_children__#{col}", :integer
      add_column :hmis_dqt_clients, "spm_adults_with_children_where_parenting_adult_18_to_24__#{col}"[0,63], :integer
      add_column :hmis_dqt_clients, "spm_without_children_and_fifty_five_plus__#{col}"[0,63], :integer
    end

  end
end
