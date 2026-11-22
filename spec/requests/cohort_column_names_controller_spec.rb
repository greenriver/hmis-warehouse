###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumnNamesController, type: :request do
  let(:user) { create(:acl_user) }
  let(:cohort_role) { create(:cohort_manager) }
  let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }
  let(:column) { CohortColumns::Active.new }

  before do
    Collection.maintain_system_groups
    GrdaWarehouse::Cohorts::CohortColumn.maintain!
    setup_access_control(user, cohort_role, all_cohorts_collection)
    sign_in user
  end

  after do
    Translation.invalidate_translation_cache(column.translation_key)
    Translation.invalidate_translation_cache(column.description_translation_key)
  end

  describe 'POST /cohort_column_names' do
    it 'stores the submitted title and description as translations for the column keys' do
      post cohort_column_names_path, params: {
        cohort_column: { column.column => 'Enrolled', "#{column.column}_description" => 'Clients currently enrolled' },
      }

      expect(response).to redirect_to(new_cohort_column_name_url)
      expect(Translation.find_by!(key: 'Active').text).to eq('Enrolled')
      expect(Translation.find_by!(key: 'Active Description').text).to eq('Clients currently enrolled')
      expect(CohortColumns::Active.new.title).to eq('Enrolled')
      expect(CohortColumns::Active.new.description).to eq('Clients currently enrolled')
    end
  end
end
