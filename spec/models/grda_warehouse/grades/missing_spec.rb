require 'rails_helper'

RSpec.describe GrdaWarehouse::Grades::Missing, type: :model do
  let(:missing_grade_a) { create :missing_grade_a }
  let(:missing_grade_b) { create :missing_grade_b}

  before(:each) do
    missing_grade_a
    missing_grade_b
  end

  describe 'When score is 7, grade' do
    it 'should be B' do
      expect( GrdaWarehouse::Grades::Missing.grade_from_score(7) ).to eq missing_grade_b
    end
  end

  describe 'When score is 4, grade' do
    it 'should be A' do
      expect( GrdaWarehouse::Grades::Missing.grade_from_score(4) ).to eq missing_grade_a
    end
  end

  describe 'When score is > 100, grade' do
    it 'should be nil' do
      expect( GrdaWarehouse::Grades::Missing.grade_from_score(107) ).to eq nil
    end
  end

  describe 'When score is negative, grade' do
    it 'should be nil' do
      expect( GrdaWarehouse::Grades::Missing.grade_from_score(-50) ).to eq nil
    end
  end
end
