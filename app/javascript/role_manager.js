import RoleManagerController from './controllers/role_manager_controller.js'

// This file is a specific entrypoint for the Role Manager page.
// It assumes that `window.Stimulus` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("role-manager", RoleManagerController)
}
