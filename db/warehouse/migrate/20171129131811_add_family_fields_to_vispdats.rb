class AddFamilyFieldsToVispdats < ActiveRecord::Migration
  def change
    add_column :vispdats, :parent2_none,                :boolean, default: false
    add_column :vispdats, :parent2_first_name,          :string
    add_column :vispdats, :parent2_nickname,            :string
    add_column :vispdats, :parent2_last_name,           :string
    add_column :vispdats, :parent2_language_answer,     :string
    add_column :vispdats, :parent2_dob,                 :date
    add_column :vispdats, :parent2_ssn,                 :string
    add_column :vispdats, :parent2_release_signed_on,   :date
    add_column :vispdats, :parent2_drug_release,        :boolean, default: false
    add_column :vispdats, :parent2_hiv_release,         :boolean, default: false

    add_column :vispdats, :number_of_children_under_18_with_family,             :integer
    add_column :vispdats, :number_of_children_under_18_with_family_refused,     :boolean, default: false
    add_column :vispdats, :number_of_children_under_18_not_with_family,         :integer
    add_column :vispdats, :number_of_children_under_18_not_with_family_refused, :boolean, default: false

    add_column :vispdats, :any_member_pregnant_answer,              :integer
    add_column :vispdats, :family_member_tri_morbidity_answer,      :integer
    add_column :vispdats, :any_children_removed_answer,             :integer
    add_column :vispdats, :any_family_legal_issues_answer,          :integer
    add_column :vispdats, :any_children_lived_with_family_answer,   :integer
    add_column :vispdats, :any_child_abuse_answer,                  :integer
    add_column :vispdats, :children_attend_school_answer,           :integer
    add_column :vispdats, :family_members_changed_answer,           :integer
    add_column :vispdats, :other_family_members_answer,             :integer
    add_column :vispdats, :planned_family_activities_answer,        :integer
    add_column :vispdats, :time_spent_alone_13_answer,              :integer
    add_column :vispdats, :time_spent_alone_12_answer,              :integer
    add_column :vispdats, :time_spent_helping_siblings_answer,      :integer
  end
end
