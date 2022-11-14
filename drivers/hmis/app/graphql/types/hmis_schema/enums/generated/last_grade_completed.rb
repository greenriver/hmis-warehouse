# header
module Types
  class HmisSchema::Enums::LastGradeCompleted < Types::BaseEnum
    description 'R4.1'
    graphql_name 'LastGradeCompleted'
    value LESS_THAN_GRADE_5, '(1) Less than grade 5', value: 1
    value GRADES_5_6, '(2) Grades 5-6', value: 2
    value GRADES_7_8, '(3) Grades 7-8', value: 3
    value GRADES_9_11, '(4) Grades 9-11', value: 4
    value GRADE_12, '(5) Grade 12', value: 5
    value SCHOOL_PROGRAM_DOES_NOT_HAVE_GRADE_LEVELS, '(6) School program does not have grade levels', value: 6
    value GED, '(7) GED', value: 7
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value SOME_COLLEGE, '(10) Some college', value: 10
    value ASSOCIATE_S_DEGREE, "(11) Associate's degree", value: 11
    value BACHELOR_S_DEGREE, "(12) Bachelor's degree", value: 12
    value GRADUATE_DEGREE, '(13) Graduate degree', value: 13
    value VOCATIONAL_CERTIFICATION, '(14) Vocational certification', value: 14
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
