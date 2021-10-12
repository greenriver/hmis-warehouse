class AdditionalHomelessSummaryFields < ActiveRecord::Migration[5.2]
  def change
    change_table :homeless_summary_report_clients do |t|
      demographic_variants = [
        :all,
        :white_non_hispanic_latino,
        :hispanic_latino,
        :black_african_american,
        :asian,
        :american_indian_alaskan_native,
        :native_hawaiian_other_pacific_islander,
        :multi_racial,
        :fleeing_dv,
        :veteran,
        :has_disability,
        :has_rrh_move_in_date,
        :has_psh_move_in_date,
        :first_time_homeless,
        :returned_to_homelessness_from_permanent_destination,
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
