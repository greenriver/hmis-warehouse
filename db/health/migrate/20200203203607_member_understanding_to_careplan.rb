class MemberUnderstandingToCareplan < ActiveRecord::Migration[5.2]
  def change
    add_column :careplans, :member_understands_contingency, :boolean
    add_column :careplans, :member_verbalizes_understanding, :boolean
  end
end
