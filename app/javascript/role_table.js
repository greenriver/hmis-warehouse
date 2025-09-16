import RoleTableController from './controllers/role_table_controller.js'

// This file is a specific entrypoint for the Role Table page.
// It assumes that `window.Stimulus` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("role-table", RoleTableController)
}
