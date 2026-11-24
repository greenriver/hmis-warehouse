###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cohort column editability', type: :model do
  let(:user) { create(:acl_user) }
  let!(:cohort_a) { create(:cohort) }
  let!(:cohort_b) { create(:cohort) }

  before { Collection.maintain_system_groups }

  def grant(permissions, cohort)
    collection = create(:collection)
    collection.set_viewables({ cohorts: [cohort.id] })
    setup_access_control(user, create(:role, **permissions.index_with { true }), collection)
  end

  def editable?(column_class, cohort, **attrs)
    column_class.new(cohort: cohort, **attrs).display_as_editable?(user, nil, on_cohort: cohort)
  end

  describe 'CohortColumns::Base#display_as_editable?' do
    it 'is editable on the cohort where the user manages data and not on another cohort' do
      grant([:can_manage_cohort_data], cohort_a)

      expect(editable?(CohortColumns::Rank, cohort_a, editable: false)).to be true
      expect(editable?(CohortColumns::Rank, cohort_b, editable: false)).to be false
    end

    it 'is editable for a participant only on the cohort granted, and only when the column is editable' do
      grant([:can_participate_in_cohorts], cohort_a)

      expect(editable?(CohortColumns::Rank, cohort_a, editable: true)).to be true
      expect(editable?(CohortColumns::Rank, cohort_a, editable: false)).to be false
      expect(editable?(CohortColumns::Rank, cohort_b, editable: true)).to be false
    end

    it 'is not editable for a viewer' do
      grant([:can_view_cohorts], cohort_a)

      expect(editable?(CohortColumns::Rank, cohort_a, editable: true)).to be false
    end
  end

  describe 'CohortColumns::Active#display_as_editable?' do
    it 'is editable only on the cohort where the user manages inactive clients' do
      grant([:can_manage_inactive_cohort_clients, :can_view_cohorts], cohort_a)

      expect(editable?(CohortColumns::Active, cohort_a)).to be true
      expect(editable?(CohortColumns::Active, cohort_b)).to be false
    end
  end

  describe 'CohortColumns::Delete#display_for' do
    let(:client) { create(:grda_warehouse_hud_client) }

    def delete_display(cohort)
      cohort_client = GrdaWarehouse::CohortClient.create!(cohort: cohort, client: client)
      CohortColumns::Delete.new(cohort: cohort, cohort_client: cohort_client).display_for(user)
    end

    it 'renders the control only on the cohort where the user can add clients' do
      grant([:can_add_cohort_clients, :can_view_cohorts], cohort_a)

      expect(delete_display(cohort_a)).to include('pre_destroy')
      expect(delete_display(cohort_b)).to eq('')
    end
  end
end
