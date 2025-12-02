###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateSitePolicyAgreements < ActiveRecord::Migration[7.1]
  def change
    create_table :compliance_agreements do |t|
      # References app db users table - no FK constraint across databases
      t.references :user, null: false, index: false
      t.references :compliance_requirement, null: false, foreign_key: true
      t.integer :revision, null: false
      t.datetime :agreed_at, null: false
      t.datetime :expires_at
      t.timestamps
    end

    add_index(
      :compliance_agreements,
      [:user_id, :compliance_requirement_id, :agreed_at],
      name: 'index_compliance_agreements_latest',
      order: { agreed_at: :desc },
    )
  end
end
