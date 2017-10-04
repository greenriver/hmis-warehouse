# NOTE: This provides an unscoped duplicate of Project for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Organization < GrdaWarehouse::Hud::Organization
    default_scope {unscope where: paranoia_column}
  end
end