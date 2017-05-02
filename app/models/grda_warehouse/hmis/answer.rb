module GrdaWarehouse::HMIS
  class Answer <  Base
    dub 'answers'

    belongs_to :assessment, inverse_of: :answers
    belongs_to :question, inverse_of: :answers
  end
end