import 'foloosi_pass_platform_interface.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'profile_data.dart';

class FoloosiPass {
  Future<void> setUpSandbox({String language = "en"}) async {
    FoloosiPassPlatform.instance.setUp(
      // clientId: "sandbox_stage",
      // clientSecret: "sandbox_stage",
      // isProduction: false,
      // urlScheme: "uaepassdemoappDS",
      // state: "123123213",
      // redirectUri: "https://oauthtest.com/authorization/return",
      // scope: "urn:uae:digitalid:profile",
      // language: language,
      clientId: "foloosi_mob_stage",
      clientSecret: "QL4Wd6oqwzMVCV1",
      isProduction: false,
      urlScheme: "foloosi",
      state: "Foloosi@123",
      redirectUri: "https://promo.foloosi.com/auth/callback/mobile",
      scope: "urn:uae:digitalid:profile",
      language: language,
    );
  }

  Future<void> setUpEnvironment({
    required String clientId,
    required String clientSecret,
    required String urlScheme,
    String state = "Foloosi@1234",
    bool isProduction = false,
    String redirectUri = "https://oauthtest.com/authorization/return",
    String scope = "urn:uae:digitalid:profile",
    String language = "en",
  }) async {
    FoloosiPassPlatform.instance.setUp(
      clientId: clientId,
      clientSecret: clientSecret,
      isProduction: isProduction,
      urlScheme: urlScheme,
      state: state,
      redirectUri: redirectUri,
      scope: scope,
      language: language,
    );
  }

  Future<String> signIn() async {
    try {
      return await FoloosiPassPlatform.instance.signIn();
    } on PlatformException catch (e) {
      throw (e.message ?? "Unknown error");
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<String> getAccessToken(String token) async {
    try {
      return await FoloosiPassPlatform.instance.getAccessToken(token);
    } on PlatformException catch (e) {
      throw (e.message ?? "Unknown error");
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<ProfileData?> getProfile(String accessToken) async {
    try {
      final result = await FoloosiPassPlatform.instance.getProfile(accessToken);
      return ProfileData.fromJson(json.decode(result));
    } on PlatformException catch (e) {
      throw (e.message ?? "Unknown error");
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      return await FoloosiPassPlatform.instance.signOut();
    } on PlatformException catch (e) {
      throw (e.message ?? "Unknown error");
    } catch (e) {
      throw (e.toString());
    }
  }
}
