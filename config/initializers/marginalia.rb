if Rails.env.development?
  Marginalia::Comment.components = [:application, :controller, :action, :line]
  Marginalia::Comment.prepend_comment = ! Rails.env.development?
  Marginalia::Comment.lines_to_ignore = /^(?!.*\/app\/.*)/
end
