# request-scoped global variables
# Using these variables is bad practice; in case of emergency break glass
class CurrentGlobalRequestScope < ActiveSupport::CurrentAttributes
  attribute :user
end
