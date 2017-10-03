module ReportGenerators::CAPER::Fy2017
  # Project Identifiers in HMIS
  class Q4a < Base
    include ReportGenerator

    ADULT = 18


    def setup_questions
      {
        q1_a1: {
          title:  nil,
          value: 'Total number of persons served',
        },
        q1_a2: {
          title:  nil,
          value: 'Number of adults (age 18 or over)',
        },
        q1_a3: {
          title:  nil,
          value: 'Number of children (under age 18)',
        },
        q1_a4: {
          title:  nil,
          value: 'Number of persons with unknown age',
        },
        q1_a5: {
          title:  nil,
          value: 'Number of leavers',
        },
        q1_a6: {
          title:  nil,
          value: 'Number of adult leavers',
        },
        q1_a7: {
          title:  nil,
          value: 'Number of adult and head of household leavers',
        },
        q1_a8: {
          title:  nil,
          value: 'Number of stayers',
        },
        q1_a9: {
          title:  nil,
          value: 'Number of adult stayers',
        },
        q1_a10: {
          title:  nil,
          value: 'Number of veterans',
        },
        q1_a11: {
          title:  nil,
          value: 'Number of chronically homeless persons',
        },
        q1_a12: {
          title:  nil,
          value: 'Number of youth under age 25',
        },
        q1_a13: {
          title:  nil,
          value: 'Number of parenting youth under age 25 with children',
        },
        q1_a14: {
          title:  nil,
          value: 'Number of adult heads of household',
        },
        q1_a15: {
          title:  nil,
          value: 'Number of child and unknown-age heads of household',
        },
        q1_a16: {
          title:  nil,
          value: 'Heads of households and adult stayers in the project 365 days or more',
        },

        q1_b1: {
          title: 'Total number of persons served ',
          value: 0,
        },
        q1_b2: {
          title: 'Number of adults (age 18 or over) ',
          value: 0,
        },
        q1_b3: {
          title: 'Number of children (under age 18) ',
          value: 0,
        },
        q1_b4: {
          title: 'Number of persons with unknown age ',
          value: 0,
        },
        q1_b5: {
          title: 'Number of leavers ',
          value: 0,
        },
        q1_b6: {
          title: 'Number of adult leavers ',
          value: 0,
        },
        q1_b7: {
          title: 'Number of adult and head of household leavers ',
          value: 0,
        },
        q1_b8: {
          title: 'Number of stayers ',
          value: 0,
        },
        q1_b9: {
          title: 'Number of adult stayers ',
          value: 0,
        },
        q1_b10: {
          title: 'Number of veterans ',
          value: 0,
        },
        q1_b11: {
          title: 'Number of chronically homeless persons ',
          value: 0,
        },
        q1_b12: {
          title: 'Number of youth under age 25 ',
          value: 0,
        },
        q1_b13: {
          title: 'Number of parenting youth under age 25 with children ',
          value: 0,
        },
        q1_b14: {
          title: 'Number of adult heads of household ',
          value: 0,
        },
        q1_b15: {
          title: 'Number of child and unknown-age heads of household ',
          value: 0,
        },
        q1_b16: {
          title: 'Heads of households and adult stayers in the project 365 days or more ',
          value: 0,
        },
      }
    end

  end
end