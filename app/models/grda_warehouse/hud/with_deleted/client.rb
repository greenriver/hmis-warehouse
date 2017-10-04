# NOTE: This provides an unscoped duplicate of Project for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Client < GrdaWarehouse::Hud::Client
    default_scope {unscope where: paranoia_column}
  end
end