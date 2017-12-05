$(".child-<%= @child.id %>").fadeOut ->
  @.remove()