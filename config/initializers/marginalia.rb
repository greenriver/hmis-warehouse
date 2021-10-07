if Rails.env.development?
  Marginalia::Comment.components = [:application, :controller, :action, :line]
  Marginalia::Comment.prepend_comment = true
  Marginalia::Comment.lines_to_ignore = /^(?!.*\/app\/.*)/
end
