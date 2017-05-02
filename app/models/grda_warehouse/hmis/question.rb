module GrdaWarehouse::HMIS
  class Question <  Base
    dub 'questions'

    has_many :answers, inverse_of: :question
  end
end