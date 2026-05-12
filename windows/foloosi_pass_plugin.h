#ifndef FLUTTER_PLUGIN_FOLOOSI_PASS_PLUGIN_H_
#define FLUTTER_PLUGIN_FOLOOSI_PASS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace foloosi_pass {

class FoloosiPassPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FoloosiPassPlugin();

  virtual ~FoloosiPassPlugin();

  // Disallow copy and assign.
  FoloosiPassPlugin(const FoloosiPassPlugin&) = delete;
  FoloosiPassPlugin& operator=(const FoloosiPassPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace foloosi_pass

#endif  // FLUTTER_PLUGIN_FOLOOSI_PASS_PLUGIN_H_
