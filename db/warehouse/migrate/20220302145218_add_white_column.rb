class AddWhiteColumn < ActiveRecord::Migration[6.1]
  def change
    change_table :homeless_summary_report_clients do |t|
      demographic_variants = [
        :white,
        :race_none,
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
