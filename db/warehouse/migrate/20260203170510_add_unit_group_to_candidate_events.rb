# frozen_string_literal: true

class AddUnitGroupToCandidateEvents < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      add_reference :ce_match_candidate_events, :unit_group, null: true, foreign_key: { to_table: :hmis_unit_groups }
    end
  end
end

# rails db:migrate:down:warehouse VERSION=20260203170510
# rails db:migrate:up:warehouse VERSION=20260203170510
