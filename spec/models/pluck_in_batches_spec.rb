require 'rails_helper'

RSpec.describe 'ActiveRecord::Relation#pluck_in_batches', type: :model do
  describe 'Pluck In Batches' do
    let!(:data_source) { create :source_data_source }
    let!(:projects) { create_list :hud_project, 53, data_source_id: data_source.id }

    context 'when fetching in batches' do
      it 'retrieves all records when batch size is 10' do
        results = []

        GrdaWarehouse::Hud::Project.all.pluck_in_batches([:ProjectID], batch_size: 10) do |batch|
          results.concat(batch)
        end

        expect(results).to match_array(projects.map(&:ProjectID))
      end

      it 'retrieves all records when batch size is equal to the count of projects' do
        results = []

        GrdaWarehouse::Hud::Project.all.pluck_in_batches([:ProjectID], batch_size: 53) do |batch|
          results.concat(batch)
        end

        expect(results).to match_array(projects.map(&:ProjectID))
      end

      it 'retrieves all records when batch size is greater than the count of projects' do
        results = []

        GrdaWarehouse::Hud::Project.all.pluck_in_batches([:ProjectID], batch_size: 100) do |batch|
          results.concat(batch)
        end

        expect(results).to match_array(projects.map(&:ProjectID))
      end

      it 'retrieves all records when multiple items are retrieved' do
        results = []

        GrdaWarehouse::Hud::Project.all.pluck_in_batches([:ProjectID, :ProjectName], batch_size: 100) do |batch|
          results.concat(batch)
        end

        expect(results).to match_array(projects.map { |p| [p.ProjectID, p.ProjectName] })
      end
    end
  end
end
