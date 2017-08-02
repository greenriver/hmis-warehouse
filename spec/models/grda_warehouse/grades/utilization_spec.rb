require 'rails_helper'

RSpec.describe GrdaWarehouse::Grades::Utilization, type: :model do

  let(:utilization_grade_a) { create :utilization_grade_a }
  let(:utilization_grade_b) { create :utilization_grade_b}
  let(:utilization_grade_f) { create :utilization_grade_f}

  before(:each) do
    utilization_grade_a
    utilization_grade_b
    utilization_grade_f
  end

  describe 'When score is 96 or 103, grade' do
    it 'should be A' do
      expect( GrdaWarehouse::Grades::Utilization.grade_from_score(96) ).to eq utilization_grade_a
      expect( GrdaWarehouse::Grades::Utilization.grade_from_score(103) ).to eq utilization_grade_a
    end
  end

  describe 'When score is 92 or 107, grade' do
    it 'should be B' do
      expect( GrdaWarehouse::Grades::Utilization.grade_from_score(92) ).to eq utilization_grade_b
      expect( GrdaWarehouse::Grades::Utilization.grade_from_score(107) ).to eq utilization_grade_b
    end
  end

  describe 'When score is 50 or > 136, grade' do
    it 'should be F' do
      expect( GrdaWarehouse::Grades::Utilization.grade_from_score(50) ).to eq utilization_grade_f
      expect( GrdaWarehouse::Grades::Utilization.grade_from_score(136) ).to eq utilization_grade_f
    end
  end

  describe 'When score is negative, grade' do
    it 'should be nil' do
      expect( GrdaWarehouse::Grades::Utilization.grade_from_score(-50) ).to eq nil
    end
  end
end
