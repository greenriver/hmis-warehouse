###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2020::Generator, type: :model do
  include_context 'path context'

  before(:all) do
    default_setup
    run(
      default_filter,
      [
        HudPathReport::Generators::Fy2020::QuestionEightToSixteen::QUESTION_NUMBER,
        HudPathReport::Generators::Fy2020::QuestionEighteen::QUESTION_NUMBER,
        HudPathReport::Generators::Fy2020::QuestionSeventeen::QUESTION_NUMBER,
        HudPathReport::Generators::Fy2020::QuestionNineteenToTwentyFour::QUESTION_NUMBER,
        HudPathReport::Generators::Fy2020::QuestionTwentyFive::QUESTION_NUMBER,
        HudPathReport::Generators::Fy2020::QuestionTwentySix::QUESTION_NUMBER,
      ],
    )
  end

  after(:all) do
    cleanup
  end

  describe 'Q8-Q16' do
    describe 'Q8' do
      it 'The number of persons contacted cannot be less than the number of persons contacted from Street Outreach Projects and Services Only Projects.' do
        persons_contacted = report_result.answer(question: 'Q8-Q16', cell: 'B2').summary
        outreach = report_result.answer(question: 'Q8-Q16', cell: 'B5').summary
        expect(persons_contacted).to be >= outreach
      end
    end

    describe 'Q11' do
      it 'The sum of the number of persons contacted from Street Outreach Projects and Services Only Projects must equal the total number of people contacted.' do
        so_and_services_only = report_result.answer(question: 'Q8-Q16', cell: 'B3').summary +
          report_result.answer(question: 'Q8-Q16', cell: 'B4').summary
        outreach = report_result.answer(question: 'Q8-Q16', cell: 'B5').summary
        expect(outreach).to eq(so_and_services_only)
      end
    end

    describe 'Q12b' do
      xit 'The Total instances of contact during the reporting period must be greater than or equal to the Number of persons contacted by PATH-funded staff this reporting period).' do
        # FIXME
        persons_contacted = report_result.answer(question: 'Q8-Q16', cell: 'B2').summary
        total_contacts = report_result.answer(question: 'Q8-Q16', cell: 'B7').summary
        expect(total_contacts).to be >= persons_contacted
      end
    end

    describe 'Q13a' do
      it 'The total number of persons who could not be enrolled because they were ineligible can\'t be greater than the total number of persons who were outreached/contacted.' do
        ineligible = report_result.answer(question: 'Q8-Q16', cell: 'B8').summary
        outreach = report_result.answer(question: 'Q8-Q16', cell: 'B5').summary
        expect(ineligible).to be <= outreach
      end

      it 'The total number of new persons who could not be enrolled because they were ineligible can\'t be greater than the total number of persons who were outreached/contacted.' do
        outreach = report_result.answer(question: 'Q8-Q16', cell: 'B5').summary
        ineligible_or_unable_to_locate = report_result.answer(question: 'Q8-Q16', cell: 'B8').summary + report_result.answer(question: 'Q8-Q16', cell: 'B9').summary
        expect(ineligible_or_unable_to_locate).to be <= outreach
      end
    end

    describe 'Q13b' do
      it 'The sum of new persons who could not be enrolled because they were ineligible and new persons who could not be enrolled because provider was unable to locate the client can\'t be greater than the total number of persons who were outreached/contacted.' do
        outreach = report_result.answer(question: 'Q8-Q16', cell: 'B5').summary
        ineligible_or_unable_to_locate = report_result.answer(question: 'Q8-Q16', cell: 'B8').summary + report_result.answer(question: 'Q8-Q16', cell: 'B9').summary
        expect(ineligible_or_unable_to_locate).to be <= outreach
      end

      it 'The total number of new persons who could not be enrolled because provider was unable to locate the client can\'t be greater than the total number of persons who were outreached/contacted.' do
        unable_to_locate = report_result.answer(question: 'Q8-Q16', cell: 'B9').summary
        outreach = report_result.answer(question: 'Q8-Q16', cell: 'B5').summary
        expect(unable_to_locate).to be <= outreach
      end
    end

    describe 'Q14' do
      it 'The total number of persons who became enrolled this reporting period cannot be greater than the total number of persons who were contacted this reporting period.' do
        outreach_enrolled = report_result.answer(question: 'Q8-Q16', cell: 'B10').summary
        persons_contacted = report_result.answer(question: 'Q8-Q16', cell: 'B2').summary
        expect(outreach_enrolled).to be <= persons_contacted
      end

      xit 'The percentage of eligible persons who became enrolled in PATH cannot be greater than 100%.' do
        # Skipped, the spec doesn't define how 'percentage of eligible persons' should be calculated
      end

      it 'The percentage of eligible new persons who became enrolled in PATH cannot be greater than 100%.' do
        outreach_enrolled = report_result.answer(question: 'Q8-Q16', cell: 'B10').summary
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        expect(outreach_enrolled).to be <= currently_enrolled_in_path
      end

      it 'The total number of new persons who became enrolled this reporting period cannot be greater than the total number of new persons who were contacted this reporting period.' do
        outreach_enrolled = report_result.answer(question: 'Q8-Q16', cell: 'B10').summary
        outreach = report_result.answer(question: 'Q8-Q16', cell: 'B5').summary
        expect(outreach_enrolled).to be <= outreach
      end
    end

    describe 'Q15' do
      it 'The total number of persons currently enrolled in PATH can\'t be less than the total number of persons who were outreach/contacted that became enrolled.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        outreach_enrolled = report_result.answer(question: 'Q8-Q16', cell: 'B10').summary
        expect(currently_enrolled_in_path).to be >= outreach_enrolled
      end

      it 'The number of persons with active, enrolled PATH status at any point during the reporting period must be less than or equal to the Number of persons contacted by PATH-funded staff this reporting period.' do
        persons_contacted = report_result.answer(question: 'Q8-Q16', cell: 'B2').summary
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        expect(currently_enrolled_in_path).to be <= persons_contacted
      end
    end

    describe 'Q16' do
      it 'The number of active PATH clients receiving community mental health services cannot be greater than the number of active clients.' do
        mental_health = report_result.answer(question: 'Q8-Q16', cell: 'B12').summary
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        expect(mental_health).to be <= currently_enrolled_in_path
      end
    end
  end

  describe 'Q17: Services Provided' do
    describe 'Q17a' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B2').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17b' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B3').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17c' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B4').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17d' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B5').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17e' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B6').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end

      xit 'The number of persons with those with an active, enrolled PATH status during this reporting period receiving mental health services in Q17e is greater than 0. Please correct this response.' do
        # FIXME: fixture has bad data
        persons_receiving_service = report_result.answer(question: 'Q17', cell: 'B6').summary
        expect(persons_receiving_service).to eq(0)
      end
    end

    describe 'Q17f' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B7').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17g' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B8').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17h' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B9').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17i' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B10').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17j' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B11').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17k' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B12').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17l' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B13').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q17m' do
      it 'The number of persons receiving a service cannot be greater than the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_service =  report_result.answer(question: 'Q17', cell: 'B14').summary
        expect(persons_receiving_service).to be <= currently_enrolled_in_path
      end
    end
  end

  describe 'Q18: Referrals Provided' do
    describe 'Q18a1' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B2').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b1' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C2').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B2').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C2').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end

      xit 'The number of persons with those with an active, enrolled PATH status during this reporting period receiving mental health referrals in Q18b1 is greater than 0. Please correct this response.' do
        # FIXME: fixture has bad data
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C2').summary
        expect(persons_attaining_referral).to eq(0)
      end
    end

    describe 'Q18a2' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B3').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b2' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C3').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B3').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C3').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a3' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B4').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b3' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C4').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B4').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C4').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a4' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B5').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b4' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C5').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B5').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C5').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a5' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B6').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b5' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C6').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B6').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C6').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a6' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B7').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b6' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C7').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B7').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C7').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a7' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B8').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b7' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C8').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B8').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C8').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a8' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B9').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b8' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C9').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B9').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C9').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a9' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B10').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b9' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C10').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B10').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C10').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a10' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B10').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b10' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C11').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C11').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end

    describe 'Q18a11' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B12').summary
        expect(persons_receiving_referral).to be <= currently_enrolled_in_path
      end
    end

    describe 'Q18b11' do
      it 'The number of persons receiving a referral cannot be greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C12').summary
        expect(persons_attaining_referral).to be <= currently_enrolled_in_path
      end

      it 'The number of persons attaining a type of referral cannot exceed the number of persons who received that type of referral.' do
        persons_receiving_referral =  report_result.answer(question: 'Q18', cell: 'B12').summary
        persons_attaining_referral =  report_result.answer(question: 'Q18', cell: 'C12').summary
        expect(persons_attaining_referral).to be <= persons_receiving_referral
      end
    end
  end

  describe 'Q19-Q24: Outcomes' do
    describe 'Q19f1' do
      it 'The total of all income categories for persons enrolled should equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        income_totals = report_result.answer(question: 'Q19-Q24', cell: 'B8').summary
        expect(income_totals).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q19f2' do
      it 'The total of enrolled people who left and stayed should equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        leavers = report_result.answer(question: 'Q19-Q24', cell: 'C8').summary
        stayers = report_result.answer(question: 'Q19-Q24', cell: 'D8').summary
        expect(currently_enrolled_in_path).to eq(leavers + stayers)
      end
    end

    describe 'Q20c1' do
      it 'The total of enrolled persons at entry with Yes; and No; responses for SSI/SSDI should equal the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        yeses = report_result.answer(question: 'Q19-Q24', cell: 'B10').summary
        nos = report_result.answer(question: 'Q19-Q24', cell: 'B11').summary
        expect(currently_enrolled_in_path).to eq(yeses + nos)
      end
    end

    describe 'Q20c2' do
      it 'The total of enrolled people who left and stayed should equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        leaver_yeses = report_result.answer(question: 'Q19-Q24', cell: 'C10').summary
        leaver_nos = report_result.answer(question: 'Q19-Q24', cell: 'C11').summary
        stayer_yeses = report_result.answer(question: 'Q19-Q24', cell: 'D10').summary
        stayer_nos = report_result.answer(question: 'Q19-Q24', cell: 'D11').summary
        expect(currently_enrolled_in_path).to eq(leaver_yeses + leaver_nos + stayer_yeses + stayer_nos)
      end
    end

    describe 'Q21f1' do
      xit 'The total of all income categories for persons enrolled should equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        income_totals = report_result.answer(question: 'Q19-Q24', cell: 'B18').summary
        expect(income_totals).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q21f2' do
      xit 'The total of enrolled people who left and stayed should equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        leavers = report_result.answer(question: 'Q19-Q24', cell: 'C18').summary
        stayers = report_result.answer(question: 'Q19-Q24', cell: 'D18').summary
        expect(currently_enrolled_in_path).to eq(leavers + stayers)
      end
    end

    describe 'Q22f1' do
      xit 'The total of all income categories for persons enrolled should equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        income_totals = report_result.answer(question: 'Q19-Q24', cell: 'B25').summary
        expect(income_totals).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q22f2' do
      xit 'The total of enrolled people who left and stayed should equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        leavers = report_result.answer(question: 'Q19-Q24', cell: 'C25').summary
        stayers = report_result.answer(question: 'Q19-Q24', cell: 'D25').summary
        expect(currently_enrolled_in_path).to eq(leavers + stayers)
      end

      xit 'The number of leavers for each applicable column: (Q19f2), (Q21f2) and (Q23f2) should be the same.' do
        # FIXME
        q19f2_leavers = report_result.answer(question: 'Q19-Q24', cell: 'C8').summary
        q21f2_leavers = report_result.answer(question: 'Q19-Q24', cell: 'C18').summary
        q23f2_leavers = report_result.answer(question: 'Q19-Q24', cell: 'C25').summary

        expect(q19f2_leavers).to eq(q21f2_leavers)
        expect(q21f2_leavers).to eq(q23f2_leavers)
      end
    end

    describe 'Q22f3' do
      xit 'The number of stayers for each applicable column: (Q19f2), (Q21f2) and (Q23f2) should be the same.' do
        # FIXME
        q19f2_stayers = report_result.answer(question: 'Q19-Q24', cell: 'D8').summary
        q21f2_stayers = report_result.answer(question: 'Q19-Q24', cell: 'D18').summary
        q23f2_stayers = report_result.answer(question: 'Q19-Q24', cell: 'D25').summary

        expect(q19f2_stayers).to eq(q21f2_stayers)
        expect(q21f2_stayers).to eq(q23f2_stayers)
      end
    end

    describe 'Q23a1' do
      it 'The number of persons with Medicaid/Medicare (23a1) cannot exceed the number of persons Covered By Health Insurance (22a1).' do
        medicaid_medicare_yes = report_result.answer(question: 'Q19-Q24', cell: 'B27').summary
        medicaid_medicare_no = report_result.answer(question: 'Q19-Q24', cell: 'B28').summary
        covered = report_result.answer(question: 'Q19-Q24', cell: 'B25').summary

        expect(covered).to be >= medicaid_medicare_yes + medicaid_medicare_no
      end
    end

    describe 'Q23c1' do
      xit 'The total of enrolled persons at entry with Yes; and No; responses for Medicaid/Medicare should equal the total number of persons with active, enrolled PATH status at any point during the reporting period).' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        medicaid_medicare_yes = report_result.answer(question: 'Q19-Q24', cell: 'B27').summary
        medicaid_medicare_no = report_result.answer(question: 'Q19-Q24', cell: 'B28').summary

        expect(currently_enrolled_in_path).to eq(medicaid_medicare_yes + medicaid_medicare_no)
      end
    end

    describe 'Q24a1' do
      it 'The number of persons with All Other Health Insurance (24a1) cannot exceed the number of persons Covered By Health Insurance (22a1).' do
        other_ins_yes = report_result.answer(question: 'Q19-Q24', cell: 'B30').summary
        other_ins_no = report_result.answer(question: 'Q19-Q24', cell: 'B31').summary
        covered = report_result.answer(question: 'Q19-Q24', cell: 'B25').summary

        expect(covered).to be >= other_ins_yes + other_ins_no
      end
    end

    describe 'Q24c1' do
      xit 'The total of enrolled persons at entry with Yes; and No; responses for All Other Health Insurance should equal the total number of persons with active, enrolled PATH status at any point during the reporting period).' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        other_ins_yes = report_result.answer(question: 'Q19-Q24', cell: 'B30').summary
        other_ins_no = report_result.answer(question: 'Q19-Q24', cell: 'B31').summary

        expect(currently_enrolled_in_path).to eq(other_ins_yes + other_ins_no)
      end
    end
  end

  describe 'Q25: Housing Outcomes' do
    describe 'Q25a41' do
      xit 'The total number of persons exiting during the reporting year may not exceed the number of persons with active, enrolled PATH status at any point during the reporting period.' do
        # FIXME
        ho_total = report_result.answer(question: 'Q25', cell: 'B44').summary
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary

        expect(ho_total).to be <= currently_enrolled_in_path
      end

      xit 'The sum of persons exiting and staying during the reporting year must equal the number of persons with active, enrolled PATH status at any point during the reporting period.' do
        # FIXME
        ho_total = report_result.answer(question: 'Q25', cell: 'B44').summary
        stayers = report_result.answer(question: 'Q25', cell: 'B45').summary
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary

        expect(currently_enrolled_in_path).to eq(ho_total + stayers)
      end
    end
  end

  describe 'Q26: Demographics' do
    describe 'Q26a9' do
      it 'The total of all gender categories for persons enrolled must equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        genders_total = report_result.answer(question: 'Q26', cell: 'C10').summary

        expect(genders_total).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q26b11' do
      it 'The total of all age categories for persons enrolled must equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        ages_total = report_result.answer(question: 'Q26', cell: 'C21').summary

        expect(ages_total).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q26c9' do
      xit 'The total of all race categories for persons enrolled should be equal to or greater than the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        races_total = (23..29).to_a.map do |row|
          cell = 'C' + row.to_s
          report_result.answer(question: 'Q26', cell: cell).summary
        end.sum

        expect(races_total).to be >= currently_enrolled_in_path
      end
    end

    describe 'Q26d6' do
      it 'The total of all ethnicity categories for persons enrolled must equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        ethnicities_total = report_result.answer(question: 'Q26', cell: 'C36').summary

        expect(ethnicities_total).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q26e6' do
      # Skipped row 177 it seems wrong?
      #
      it 'The total of all veteran categories for persons enrolled must equal the total number of people with active, enrolled PATH status at any point during the reporting periods that are adults (18+ years old).' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        under_eighteen = report_result.answer(question: 'Q26', cell: 'C11').summary
        total_veterans = report_result.answer(question: 'Q26', cell: 'C42').summary

        expect(total_veterans).to eq(currently_enrolled_in_path - under_eighteen)
      end
    end

    describe 'Q26f4' do
      it 'The total of all co-occurring disorder categories for persons enrolled must equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        co_occurring_disorders = report_result.answer(question: 'Q26', cell: 'C46').summary

        expect(co_occurring_disorders).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q26g6' do
      xit 'The total of all SOAR Connection categories for persons enrolled should equal the total number of persons with active, enrolled PATH status at any point during the reporting period.' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        soar_total = report_result.answer(question: 'Q26', cell: 'C52').summary

        expect(soar_total).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q26h29' do
      it 'The total of all living situation categories for persons enrolled must equal the total number of people with active, enrolled PATH status at any point during the reporting period).' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        prior_ls_sum = (54..83).to_a.map do |row|
          cell = 'C' + row.to_s
          report_result.answer(question: 'Q26', cell: cell).summary
        end.compact.sum

        expect(prior_ls_sum).to eq(currently_enrolled_in_path)
      end

      it 'The total of all living situation categories for persons enrolled must equal the total number of people with active, enrolled PATH status at any point during the reporting period).' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        prior_ls_total = report_result.answer(question: 'Q26', cell: 'C84').summary

        expect(prior_ls_total).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q26i10' do
      it 'The total of this category must equal the sum of Place not meant for habitation (Q26h1) and Emergency shelter (Q26h2).' do
        los_total = report_result.answer(question: 'Q26', cell: 'C94').summary
        street_or_es = report_result.answer(question: 'Q26', cell: 'C54').summary + report_result.answer(question: 'Q26', cell: 'C55').summary

        expect(los_total).to eq(street_or_es)
      end
    end

    describe 'Q26j4' do
      it 'The total of all Chronically homeless categories for persons enrolled should equal the total number of people with active, enrolled PATH status at any point during the reporting period.' do
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        chronic_total = report_result.answer(question: 'Q26', cell: 'C98').summary

        expect(chronic_total).to eq(currently_enrolled_in_path)
      end
    end

    describe 'Q26k6' do
      xit 'The total of all Domestic Violence History categories for adults enrolled should equal the total number of adults with active, enrolled PATH status at any point during the reporting period. ' do
        # FIXME
        currently_enrolled_in_path = report_result.answer(question: 'Q8-Q16', cell: 'B11').summary
        dv_total = report_result.answer(question: 'Q26', cell: 'C104').summary

        expect(dv_total).to eq(currently_enrolled_in_path)
      end
    end
  end
end
