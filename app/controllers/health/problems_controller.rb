module Health
  class ProblemsController < Window::Health::ProblemsController
    include ClientPathGenerator
  end
end