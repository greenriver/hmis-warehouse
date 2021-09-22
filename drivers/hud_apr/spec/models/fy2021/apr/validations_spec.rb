###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::Generator, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(
      default_filter,
      [
        HudApr::Generators::Apr::Fy2021::QuestionFive::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionSix::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionSeven::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionEight::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionNine::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionTen::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionEleven::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionTwelve::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionThirteen::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionFourteen::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionFifteen::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionSixteen::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionEighteen::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionNineteen::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionTwenty::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionTwentyTwo::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionTwentyThree::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionTwentyFive::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionTwentySix::QUESTION_NUMBER,
        HudApr::Generators::Apr::Fy2021::QuestionTwentySeven::QUESTION_NUMBER,
      ],
    )
  end

  after(:all) do
    cleanup
  end

  describe 'APR reports' do
    describe 'Confirms that we conform with APR spec' do
      describe 'Q6 tests' do
        # 6a :: Float in Q6a column F cannot be greater than 1.
        (2..8).each do |i|
          it "Confirm that we're not getting nil, because nil.to_f would pass the second test #{i}" do
            # Confirm that we're not getting nil, because nil.to_f would pass the second test
            expect(report_result.answer(question: 'Q6a', cell: "F#{i}").summary.class).not_to be NilClass
            expect(report_result.answer(question: 'Q6a', cell: "F#{i}").summary.to_f).to be <= 1
          end
        end

        # 6b :: Float in Q6b column C cannot be greater than 1.
        (2..6).each do |i|
          it "Confirm that we're not getting nil, because nil.to_f would pass the second test #{i}" do
            # Confirm that we're not getting nil, because nil.to_f would pass the second test
            expect(report_result.answer(question: 'Q6b', cell: "C#{i}").summary.class).not_to be NilClass
            expect(report_result.answer(question: 'Q6b', cell: "C#{i}").summary.to_f).to be <= 1
          end
        end

        # 6c :: Float in Q6c column C cannot be greater than 1.
        (2..5).each do |i|
          it "Confirm that we're not getting nil, because nil.to_f would pass the second test #{i}" do
            # Confirm that we're not getting nil, because nil.to_f would pass the second test
            expect(report_result.answer(question: 'Q6c', cell: "C#{i}").summary.class).not_to be NilClass
            expect(report_result.answer(question: 'Q6c', cell: "C#{i}").summary.to_f).to be <= 1
          end
        end

        # 6d :: Float in Q6d column H cannot be greater than 1.
        (2..5).each do |i|
          it "Confirm that we're not getting nil, because nil.to_f would pass the second test #{i}" do
            # Confirm that we're not getting nil, because nil.to_f would pass the second test
            expect(report_result.answer(question: 'Q6d', cell: "H#{i}").summary.class).not_to be NilClass
            expect(report_result.answer(question: 'Q6d', cell: "H#{i}").summary.to_f).to be <= 1
          end
        end

        # 6f :: Float in Q6f column D cannot be greater than 1.
        (2..3).each do |i|
          it "Confirm that we're not getting nil, because nil.to_f would pass the second test #{i}" do
            # Confirm that we're not getting nil, because nil.to_f would pass the second test
            expect(report_result.answer(question: 'Q6f', cell: "D#{i}").summary.class).not_to be NilClass
            expect(report_result.answer(question: 'Q6f', cell: "D#{i}").summary.to_f).to be <= 1
          end
        end
      end

      it '7a :: Total in Q7a B6 must equal total persons from Q5a B1' do
        # 7a :: Total in Q7a B6 must equal total persons from Q5a B1
        expect(report_result.answer(question: 'Q7a', cell: 'B6').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B1').summary)
      end

      it '8a :: Q8A B2 must equal the sum of adult heads of household plus child and unknown-age heads of household in Q5A B14 + B15.' do
        # 8a :: Q8A B2 must equal the sum of adult heads of household plus child and unknown-age heads of household in Q5A B14 + B15.
        expect(report_result.answer(question: 'Q8a', cell: 'B2').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B14').summary + report_result.answer(question: 'Q5a', cell: 'B15').summary)
      end

      # 9b :: Float in Q9b row 7 cannot be greater than 1.
      ['B', 'C', 'D', 'E'].each do |i|
        it "9b :: Float in Q9b row 7 cannot be greater than 1. #{i}" do
          # Confirm that we're not getting nil, because nil.to_f would pass the second test
          expect(report_result.answer(question: 'Q9b', cell: "#{i}7").summary.class).not_to be NilClass
          expect(report_result.answer(question: 'Q9b', cell: "#{i}7").summary.to_f).to be <= 1
        end
      end

      it 'Total in Q10a B9 must equal total adults in Q5a B2.' do
        # Total in Q10a B9 must equal total adults in Q5a B2.
        expect(report_result.answer(question: 'Q10a', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B2').summary)
      end

      it 'Total in Q10b B9 must equal total children in Q5a B3.' do
        # Total in Q10b B9 must equal total children in Q5a B3.
        expect(report_result.answer(question: 'Q10b', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B3').summary)
      end

      it 'Total in Q10c B9 must equal total with unknown age in Q5a B4.' do
        # Total in Q10c B9 must equal total with unknown age in Q5a B4.
        expect(report_result.answer(question: 'Q10c', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B4').summary)
      end

      it 'Total in Q11 B13 must equal total persons from Q5A B1.' do
        # Total in Q11 B13 must equal total persons from Q5A B1.
        expect(report_result.answer(question: 'Q11', cell: 'B13').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B1').summary)
      end

      it 'Total in Q12a B10 must equal total persons from Q5A B1.' do
        # Total in Q12a B10 must equal total persons from Q5A B1.
        expect(report_result.answer(question: 'Q12a', cell: 'B10').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B1').summary)
      end

      it 'Total in Q12b B6 must equal total persons from Q5A B1.' do
        # Total in Q12b B6 must equal total persons from Q5A B1.
        expect(report_result.answer(question: 'Q12b', cell: 'B6').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B1').summary)
      end

      it 'Total in Q13A2 B9 must equal total persons from Q5A B1.' do
        # Total in Q13A2 B9 must equal total persons from Q5A B1.
        expect(report_result.answer(question: 'Q13a2', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B1').summary)
      end

      it 'Total in Q13B2 B9 must equal total leavers from Q5A B5.' do
        # Total in Q13B2 B9 must equal total leavers from Q5A B5.
        expect(report_result.answer(question: 'Q13b2', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B5').summary)
      end

      it 'Total in Q13C2 B9 must equal total stayer from Q5A B8.' do
        # Total in Q13C2 B9 must equal total stayer from Q5A B8.
        expect(report_result.answer(question: 'Q13c2', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B8').summary)
      end

      it 'Total in Q14A B6 must equal the sum of adults plus child and unknown-age heads of household in Q5A B14 + B15.' do
        # Total in Q14A B6 must equal the sum of adults plus child and unknown-age heads of household in Q5A B14 + B15.
        expect(report_result.answer(question: 'Q14a', cell: 'B6').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B14').summary + report_result.answer(question: 'Q5a', cell: 'B15').summary)
      end

      it 'Total in Q14A B35 must equal the sum of adults plus child and unknown-age heads of household in Q5A B14 + B15.' do
        # Total in Q14A B35 must equal the sum of adults plus child and unknown-age heads of household in Q5A B14 + B15.
        expect(report_result.answer(question: 'Q15', cell: 'B35').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B14').summary + report_result.answer(question: 'Q5a', cell: 'B15').summary)
      end

      it 'Total at start in Q16 B14 must equal total adults in Q5A B2.' do
        # Total at start in Q16 B14 must equal total adults in Q5A B2.
        expect(report_result.answer(question: 'Q16', cell: 'B14').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B2').summary)
      end

      it 'Total at exit in Q16 D14 must equal total adult leavers in Q5A B6.' do
        # Total at exit in Q16 D14 must equal total adult leavers in Q5A B6.
        expect(report_result.answer(question: 'Q16', cell: 'D14').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B6').summary)
      end

      it 'Total at exit in Q16 C14 must equal total adult stayers in Q5A B9.' do
        # Total at exit in Q16 C14 must equal total adult stayers in Q5A B9.
        expect(report_result.answer(question: 'Q16', cell: 'C14').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B9').summary)
      end

      it 'Total at exit in Q18 D10 must equal total adult leavers in Q5A B6.' do
        # Total at exit in Q18 D10 must equal total adult leavers in Q5A B6.
        expect(report_result.answer(question: 'Q18', cell: 'D10').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B6').summary)
      end

      it 'Total at start in Q18 B10 must equal total adults in Q5A B2.' do
        # Total at start in Q18 B10 must equal total adults in Q5A B2.
        expect(report_result.answer(question: 'Q18', cell: 'B10').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B2').summary)
      end

      it 'Total stayers in Q18 C10 must equal total adult stayers in Q5A B9.' do
        # Total stayers in Q18 C10 must equal total adult stayers in Q5A B9.
        expect(report_result.answer(question: 'Q18', cell: 'C10').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B9').summary)
      end

      # Floats in Q19a1 cannot be greater than 1.
      [2, 4, 6].each do |i|
        it "Confirm that we're not getting nil, because nil.to_f would pass the second test #{i}" do
          # Confirm that we're not getting nil, because nil.to_f would pass the second test
          expect(report_result.answer(question: 'Q19a1', cell: "J#{i}").summary.class).not_to be NilClass
          expect(report_result.answer(question: 'Q19a1', cell: "J#{i}").summary.to_f).to be <= 1
        end
      end

      # Floats in Q19a2 cannot be greater than 1.
      [2, 4, 6].each do |i|
        it "Confirm that we're not getting nil, because nil.to_f would pass the second test #{i}" do
          # Confirm that we're not getting nil, because nil.to_f would pass the second test
          expect(report_result.answer(question: 'Q19a2', cell: "J#{i}").summary.class).not_to be NilClass
          expect(report_result.answer(question: 'Q19a2', cell: "J#{i}").summary.to_f).to be <= 1
        end
      end

      # Floats in Q19b cannot be greater than 1.
      (2..13).each do |n|
        ['E', 'I', 'M'].each do |l|
          it "Confirm that we're not getting nil, because nil.to_f would pass the second test #{l}#{n}" do
            # Confirm that we're not getting nil, because nil.to_f would pass the second test
            expect(report_result.answer(question: 'Q19b', cell: "#{l}#{n}").summary.class).not_to be NilClass
            expect(report_result.answer(question: 'Q19b', cell: "#{l}#{n}").summary.to_f).to be <= 1
          end
        end
      end

      it 'Total at start in Q20B B6 must equal total adults in Q5A B2.' do
        # Total at start in Q20B B6 must equal total adults in Q5A B2.
        expect(report_result.answer(question: 'Q20b', cell: 'B6').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B2').summary)
      end

      it 'Total at exit in Q20B D6 must be less than or equal to total adult leavers in Q5A B6.' do
        # Total at exit in Q20B D6 must be less than or equal to total adult leavers in Q5A B6.
        expect(report_result.answer(question: 'Q20b', cell: 'D6').summary).to be <= report_result.answer(question: 'Q5a', cell: 'B6').summary
      end

      it 'Total in Q22A1 B13 must equal total persons from Q5A B1.' do
        # Total in Q22A1 B13 must equal total persons from Q5A B1.
        expect(report_result.answer(question: 'Q22a1', cell: 'B13').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B1').summary)
      end

      it 'Total in Q22C B13 must be less than or equal to total_persons_served in Q5A ({1}).' do
        # Total in Q22C B13 must be less than or equal to total_persons_served in Q5A ({1}).
        expect(report_result.answer(question: 'Q22c', cell: 'B13').summary).to be <= report_result.answer(question: 'Q5a', cell: 'B1').summary
      end

      it 'Total in Q22E B14 must equal total persons from Q5A B1.' do
        # Total in Q22E B14 must equal total persons from Q5A B1.
        expect(report_result.answer(question: 'Q22e', cell: 'B14').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B1').summary)
      end

      it 'Total at exit in Q23C B39 must equal total leavers in Q5A B5.' do
        # Total at exit in Q23C B39 must equal total leavers in Q5A B5.
        expect(report_result.answer(question: 'Q23c', cell: 'B43').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B5').summary)
      end

      # Floats in 23c cannot be greater than 1.
      ['B', 'C', 'D', 'E', 'F'].each do |l|
        it "Floats in 23c cannot be greater than 1. #{l}" do
          expect(report_result.answer(question: 'Q23c', cell: "#{l}46").summary.class).not_to be NilClass
          expect(report_result.answer(question: 'Q23c', cell: "#{l}46").summary.to_f).to be <= 1
        end
      end

      it 'Total CH vets plus non-CH vets in Q25A B2 + B3  must equal veterans in Q5A B10.' do
        # Total CH vets plus non-CH vets in Q25A B2 + B3  must equal veterans in Q5A B10.
        expect(report_result.answer(question: 'Q25a', cell: 'B2').summary + report_result.answer(question: 'Q25a', cell: 'B3').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B10').summary)
      end

      it 'Total in Q25C B9 in Q5A B10 must equal veterans in Q5A B10.' do
        # Total in Q25C B9 in Q5A B10 must equal veterans in Q5A B10.
        expect(report_result.answer(question: 'Q25c', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B10').summary)
      end

      it 'Total in Q25D B10 must be greater than or equal to veterans in Q5A B10.' do
        # Total in Q25D B10 must be greater than or equal to veterans in Q5A B10.
        expect(report_result.answer(question: 'Q25d', cell: 'B10').summary).to be >= report_result.answer(question: 'Q5a', cell: 'B10').summary
      end

      it 'Total in Q25F B10 must equal veterans in Q5A B10.' do
        # Total in Q25F B10 must equal veterans in Q5A B10.
        expect(report_result.answer(question: 'Q25f', cell: 'B10').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B10').summary)
      end

      it 'Total in Q25I B39 must be less than or equal to veterans in Q5A B10.' do
        # Total in Q25I B39 must be less than or equal to veterans in Q5A B10.
        expect(report_result.answer(question: 'Q25i', cell: 'B43').summary).to be <= report_result.answer(question: 'Q5a', cell: 'B10').summary
      end

      # Floats in percentage row in Q25I cannot be greater than 1.
      ['B', 'C', 'D', 'E', 'F'].each do |l|
        it "Floats in percentage row in Q25I cannot be greater than 1. #{l}" do
          expect(report_result.answer(question: 'Q25i', cell: "#{l}46").summary.class).not_to be NilClass
          expect(report_result.answer(question: 'Q25i', cell: "#{l}46").summary.to_f).to be <= 1
        end
      end

      it 'Total chronically homeless in Q26A B2 must be less than or equal to chronically homeless in Q5A B11.' do
        # Total chronically homeless in Q26A B2 must be less than or equal to chronically homeless in Q5A B11.
        expect(report_result.answer(question: 'Q26a', cell: 'B2').summary).to be <= report_result.answer(question: 'Q5a', cell: 'B11').summary
      end

      it 'Total chronically homeless in Q26B B2 must equal chronically homeless in Q5A B11.' do
        # Total chronically homeless in Q26B B2 must equal chronically homeless in Q5A B11.
        expect(report_result.answer(question: 'Q26b', cell: 'B2').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B11').summary)
      end

      it 'Total in Q26C B9 must equal chronically homeless in Q5A B11.' do
        # Total in Q26C B9 must equal chronically homeless in Q5A B11.
        expect(report_result.answer(question: 'Q26c', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B11').summary)
      end

      it 'Total in Q26D B11 must equal chronically homeless in Q5A B11.' do
        # Total in Q26D B11 must equal chronically homeless in Q5A B11.
        expect(report_result.answer(question: 'Q26d', cell: 'B11').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B11').summary)
      end

      it 'Total at start in Q26F B10 must less than or equal to chronically homeless in Q5A B11.' do
        # Total at start in Q26F B10 must less than or equal to chronically homeless in Q5A B11.
        expect(report_result.answer(question: 'Q26f', cell: 'B10').summary).to be <= report_result.answer(question: 'Q5a', cell: 'B11').summary
      end

      it 'Total in Q27A B6 must equal youth under age 25 in Q5A B12.' do
        # Total in Q27A B6 must equal youth under age 25 in Q5A B12.
        expect(report_result.answer(question: 'Q27a', cell: 'B6').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B12').summary)
      end

      it 'Total parenting youth in Q27B B2 + B3 must equal parenting youth under 25 with children in Q5A B13.' do
        # Total parenting youth in Q27B B2 + B3 must equal parenting youth under 25 with children in Q5A B13.
        expect(report_result.answer(question: 'Q27b', cell: 'B2').summary + report_result.answer(question: 'Q27b', cell: 'B3').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B13').summary)
      end

      it 'Total in Q27C B9 must equal youth under age 25 in Q5A B12.' do
        # Total in Q27C B9 must equal youth under age 25 in Q5A B12.
        expect(report_result.answer(question: 'Q27c', cell: 'B9').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B12').summary)
      end

      it 'Total in Q27D B38 must less than or equal to youth under age 25 in Q5A B12.' do
        # Total in Q27D B38 must less than or equal to youth under age 25 in Q5A B12.
        expect(report_result.answer(question: 'Q27d', cell: 'B35').summary).to be <= report_result.answer(question: 'Q5a', cell: 'B12').summary
      end

      it 'Total in Q27E B13 must equal youth under age 25 in Q5A B12.' do
        # Total in Q27E B13 must equal youth under age 25 in Q5A B12.
        expect(report_result.answer(question: 'Q27e', cell: 'B13').summary).to eq(report_result.answer(question: 'Q5a', cell: 'B12').summary)
      end

      it 'Total in Q27F B43 must be less than or equal to youth under age 25 in Q5A B12.' do
        # Total in Q27F B43 must be less than or equal to youth under age 25 in Q5A B12.
        expect(report_result.answer(question: 'Q27f', cell: 'B43').summary).to be <= report_result.answer(question: 'Q5a', cell: 'B12').summary
      end

      # Float percentage in Q27f cannot be greater than 1.
      ['B', 'C', 'D', 'E', 'F'].each do |l|
        it "Float percentage in Q27f cannot be greater than 1. #{l}" do
          expect(report_result.answer(question: 'Q27f', cell: "#{l}46").summary.class).not_to be NilClass
          expect(report_result.answer(question: 'Q27f', cell: "#{l}46").summary.to_f).to be <= 1
        end
      end

      # Float percentage in Q27i cannot be greater than 1.
      ['E', 'I', 'M', 'Q'].each do |l|
        (2..13).each do |n|
          it "Float percentage in Q27i cannot be greater than 1. #{l}#{n}" do
            expect(report_result.answer(question: 'Q27i', cell: "#{l}#{n}").summary.class).not_to be NilClass
            expect(report_result.answer(question: 'Q27i', cell: "#{l}#{n}").summary.to_f).to be <= 1
          end
        end
      end
    end
  end
end
