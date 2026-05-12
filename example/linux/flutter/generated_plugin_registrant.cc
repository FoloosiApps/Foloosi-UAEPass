//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <foloosi_pass/foloosi_pass_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) foloosi_pass_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FoloosiPassPlugin");
  foloosi_pass_plugin_register_with_registrar(foloosi_pass_registrar);
}
