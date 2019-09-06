$("#file-<%= @file.id %>").fadeOut 'normal', ->
  @.remove()