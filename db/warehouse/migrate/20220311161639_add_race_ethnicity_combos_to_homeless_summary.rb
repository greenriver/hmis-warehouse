class AddRaceEthnicityCombosToHomelessSummary < ActiveRecord::Migration[6.1]
  def change
    change_table :homeless_summary_report_clients do |t|
      demographic_variants = [
        :non_hispanic_latino,
        :b_n_h_l,
        :a_n_h_l,
        :n_n_h_l,
        :h_n_h_l,
      ]
      household_variants = [
        :all_persons,
        :without_children,
        :with_children,
        :only_children,
        :without_children_and_fifty_five_plus,
        :adults_with_children_where_parenting_adult_18_to_24,
      ]
      household_variants.each do |hh_variant|
        demographic_variants.each do |demo_variant|
          t.integer "spm_#{hh_variant}__#{demo_variant}"
        end
      end
    end
  end
end
