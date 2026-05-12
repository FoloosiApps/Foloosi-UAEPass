#include "include/foloosi_pass/foloosi_pass_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "foloosi_pass_plugin.h"

void FoloosiPassPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  foloosi_pass::FoloosiPassPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
