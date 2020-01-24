'@Only
'@TestSuite ACVMT

namespace ACVMT

'@BeforeEach
function beforeEach()
  m.view = { "id": "appController" }
  m.modelLocator = createObject("roSGNode", "ModelLocator")
  m.modelLocator.plugins = []

  TU.setModelLocator(m.modelLocator)

  m.vm = AppControllerVM(m.view, m.modelLocator, m.global)
end function

'@AfterEach
function afterEach()
  TU.unsetModelLocator()
end function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests constructor
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function constructor()
  m.assertEqual(m.vm.view, m.view)
  m.assertEqual(m.vm.modelLocator, m.modelLocator)
  m.assertNotInvalid(m.vm.pluginProvider)
  m.assertNotInvalid(m.vm.deeplinkingNavItem)
  m.assertEqual(m.vm.deeplinkingNavItem.id, "deeplinkingController")
  m.assertEqual(m.vm.deeplinkingNavItem.title, "deeplinkingController")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests configureModelLocator
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test no gamp
'@Params[{}]
'@Params[{system_analytics_account:invalid}]
'@Params[{system_analytics_account:""}]
function configureModelLocator_no_gamp(account)
  gamp = { "id": "googleAnalytics" }
  seg = { "id": "segmentAnalyticsManager" }

  TU.setModelLocator({
    id: "fakeModelLocator"
    user: {
      "account": account
    }
  })

  m.expectOnce(m.vm, "createInstance", ["GampTask", invalid, "googleAnalytics"], gamp)
  m.expectOnce(m.vm, "createInstance", ["SegmentAnalyticsManager", invalid, "segmentAnalyticsManager"], seg)

  m.expectOnce(m.vm, "setInstance", ["analytics", gamp])
  m.expectOnce(m.vm, "setInstance", ["segmentAnalyticsManager", seg])

  m.vm.configureModelLocator()

  m.assertInvalid(gamp.trackingId)
  m.assertInvalid(gamp.clientId)
  m.assertInvalid(gamp.control)

end function

'@Test gamp
function configureModelLocator_gamp()
  gamp = { "id": "googleAnalytics" }
  seg = { "id": "segmentAnalyticsManager" }

  TU.setModelLocator({
    id: "fakeModelLocator"
    user: {
      "account": {
        system_analytics_account: "saa"
      }
    }
    constants: {
      googleAnalyticsClientId: "gid"
    }
  })

  m.expectOnce(m.vm, "createInstance", ["GampTask", invalid, "googleAnalytics"], gamp)
  m.expectOnce(m.vm, "createInstance", ["SegmentAnalyticsManager", invalid, "segmentAnalyticsManager"], seg)

  m.expectOnce(m.vm, "setInstance", ["analytics", gamp])
  m.expectOnce(m.vm, "setInstance", ["segmentAnalyticsManager", seg])

  m.vm.configureModelLocator()

  m.assertEqual(gamp.trackingId, "saa")
  m.assertEqual(gamp.clientId, "gid")
  m.assertEqual(gamp.control, "run")

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests initializeApp
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test no isInitialLaunch
function initializeApp_noisInitialLaunch()
  m.expectOnce(m.vm, "resetLoadingFlags")
  m.expectOnce(m.vm, "initializeZappSDK")
  m.expectOnce(m.vm, "initializeAnalyticsPlugins")
  m.expectNone(m.vm, "setScreenLoadingFlag")
  m.expectNone(m.vm, "postAnalyticsEvent")
  m.expectNone(m.vm, "isDeepLinkingRequired")

  m.vm.isInitialLaunch = false

  m.vm.initializeApp()
end function

'@Test deeplinking required
function initializeApp_deeplinking_required()
  launchArgs = { "id": "la" }

  m.expectOnce(m.vm, "resetLoadingFlags")
  m.expectOnce(m.vm, "getInstance", ["launchArgs"], launchArgs)
  m.expectOnce(m.vm, "initializeZappSDK")
  m.expectOnce(m.vm, "initializeAnalyticsPlugins")
  m.expectOnce(m.vm, "isDeeplinkingRequired", [launchArgs], true)
  m.expectOnce(m.vm, "processLiveDeeplinkingArgs", [launchArgs])
  m.expectOnce(m.vm, "setScreenLoadingFlag", ["appController", false])
  m.expectOnce(m.vm, "postAnalyticsEvent", invalid)
  m.expectOnce(m.vm, "getAnalyticsEvent", invalid)

  m.expectNone(m.vm, "configureNavMenu")
  m.expectNone(m.vm, "navigateToHomeItem")
  m.expectNone(m.vm, "toggleNavMenuFocus")

  m.vm.isInitialLaunch = true

  m.vm.initializeApp()

  m.assertFalse(m.vm.isInitialLaunch)
end function

'@Test no deeplinking
function initializeApp_no_deeplinking()
  launchArgs = { "id": "la" }

  m.expectOnce(m.vm, "resetLoadingFlags")
  m.expectOnce(m.vm, "getInstance", ["launchArgs"], launchArgs)
  m.expectOnce(m.vm, "initializeZappSDK")
  m.expectOnce(m.vm, "initializeAnalyticsPlugins")
  m.expectOnce(m.vm, "isDeeplinkingRequired", [launchArgs], false)
  m.expectNone(m.vm, "processLiveDeeplinkingArgs")
  m.expectOnce(m.vm, "setScreenLoadingFlag", ["appController", false])
  m.expectOnce(m.vm, "postAnalyticsEvent", invalid)
  m.expectOnce(m.vm, "getAnalyticsEvent", invalid)

  m.expectOnce(m.vm, "configureNavMenu")
  m.expectOnce(m.vm, "navigateToHomeItem")
  m.expectOnce(m.vm, "toggleNavMenuFocus", [false])

  m.vm.isInitialLaunch = true

  m.vm.initializeApp()

  m.assertFalse(m.vm.isInitialLaunch)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests initializeAnalyticsPlugins
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function initializeAnalyticsPlugins()
  sam = { "id": "sam" }
  m.expectOnce(m.vm, "getInstance", ["segmentAnalyticsManager"], sam)
  m.expectOnce(sam, "callFunc", ["identify", "gygia"])

  m.vm.initializeAnalyticsPlugins()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests initializeZappSDK
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function initializeZappSDK()
  map = { "id": "map" }
  m.expectOnce(m.vm, "getApplicasterPluginMap", invalid, map)
  m.expectOnce(m.vm, "initZappFrameworks", [{ "matcher": function(value)
        return value.useZappPipes = true and value.useUIBuilder = true and value.pluginMap.id = "map"
  end function }])

  m.vm.initializeZappSDK()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests getApplicasterPluginMap
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function getApplicasterPluginMap()
  m.vm.getApplicasterPluginMap()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests showPreHookIfRequired
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function showPreHookIfRequired_no_plugins()
  m.expectOnce(m.vm.pluginProvider, "getStartupPlugins", [], [])
  m.expectNone(m.vm, "push")

  m.assertFalse(m.vm.showPreHookIfRequired())

end function

'@Test  one - not showing
function showPreHookIfRequired_one_not_showing()
  plugin = { "id": "plugin" }
  m.expectOnce(plugin, "isScreenShowing", [], false)

  m.expectOnce(m.vm.pluginProvider, "getStartupPlugins", [], [plugin])
  m.expectNone(m.vm, "push")

  m.assertFalse(m.vm.showPreHookIfRequired())

end function

'@Test  one - badly configure
'@Params[{"id": "plugin"}, ""]
'@Params[{"id": "plugin", "screenType": invalid}, ""]
'@Params[{"id": "plugin", "screenType": ""}, ""]
function showPreHookIfRequired_one_badly_configured(plugin, screenName)
  m.expectOnce(plugin, "isScreenShowing", [], true)
  m.expectOnce(plugin, "getStringValue", ["screen_name", ""], screenName)

  m.expectOnce(m.vm.pluginProvider, "getStartupPlugins", [], [plugin])
  m.expectNone(m.vm, "getScreenByName")
  m.expectNone(m.vm, "createInstance")
  m.expectNone(m.vm, "push")

  m.assertFalse(m.vm.showPreHookIfRequired())

end function

'@Test  screenName - unknown
function showPreHookIfRequired_one_screenName_unknown()
  plugin = { "id": "plugin", "screeName": "unknown" }

  m.expectOnce(plugin, "isScreenShowing", [], true)
  m.expectOnce(plugin, "getStringValue", ["screen_name", ""], "unknown")
  m.expectOnce(m.vm, "getScreenByName", ["unknown"], invalid)

  m.expectOnce(m.vm.pluginProvider, "getStartupPlugins", [], [plugin])
  m.expectNone(m.vm, "createInstance")
  m.expectNone(m.vm, "push")

  m.assertFalse(m.vm.showPreHookIfRequired())
end function

'@Test  screenName - known
function showPreHookIfRequired_one_screenName_known()
  plugin = { "id": "plugin", "screeName": "known" }
  screen = { "id": "screen" }

  m.expectOnce(plugin, "isScreenShowing", [], true)
  m.expectOnce(plugin, "getStringValue", ["screen_name", ""], "known")
  m.expectOnce(m.vm, "getScreenByName", ["known"], screen)

  m.expectOnce(m.vm.pluginProvider, "getStartupPlugins", [], [plugin])

  m.expectOnce(m.vm, "bindNodeField", [screen, "state", "onPrehookStateChange", MOM.createBindingProperties(false, invalid, true)])
  m.expectOnce(m.vm, "push", [screen])
  m.expectOnce(m.vm, "setFocus", [screen])

  m.expectNone(m.vm, "createInstance")

  m.assertTrue(m.vm.showPreHookIfRequired())

  m.assertEqual(m.vm.prehookScreen, screen)
  m.assertEqual(screen.id, "prehookScreen")

end function

'@Test  screenType - unknown
function showPreHookIfRequired_one_screenType_unknown()
  plugin = { "id": "plugin", screenType: "unknown" }

  m.expectOnce(plugin, "isScreenShowing", [], true)
  m.expectOnce(plugin, "getStringValue", ["screen_name", ""], "")
  m.expectOnce(m.vm, "createInstance", ["unknown"], invalid)

  m.expectOnce(m.vm.pluginProvider, "getStartupPlugins", [], [plugin])
  m.expectNone(m.vm, "push")

  m.assertFalse(m.vm.showPreHookIfRequired())
end function

'@Test  screenType - known - plugin
'@Params[{ "id": "plugin", screenType: "known" }]
'@Params[{ "id": "plugin", screenType: "known", isUsingScreenRiversJson:invalid }]
'@Params[{ "id": "plugin", screenType: "known", isUsingScreenRiversJson:false }]
function showPreHookIfRequired_one_screenType_known_plugin_json(plugin)
  plugin.config = { "id": "config" }

  screen = { "id": "screen" }

  m.expectOnce(plugin, "isScreenShowing", [], true)
  m.expectOnce(plugin, "getStringValue", ["screen_name", ""], "")
  m.expectOnce(m.vm, "createInstance", ["known"], screen)

  m.expectOnce(m.vm.pluginProvider, "getStartupPlugins", [], [plugin])

  m.expectOnce(m.vm, "bindNodeField", [screen, "state", "onPrehookStateChange", MOM.createBindingProperties(false, invalid, true)])
  m.expectOnce(m.vm, "push", [screen])
  m.expectOnce(m.vm, "setFocus", [screen])

  m.assertTrue(m.vm.showPreHookIfRequired())

  m.assertEqual(screen.id, "prehookScreen")
  m.assertEqual(m.vm.prehookScreen, screen)
  m.assertEqual(m.vm.prehookScreen.riversJson.id, "known")
  m.assertEqual(m.vm.prehookScreen.riversJson.data, plugin.config)
end function

'@Test  screenType - known - default json
function showPreHookIfRequired_one_screenType_known_use_default_json()
  plugin = { "id": "plugin", screenType: "known", isUsingScreenRiversJson: true }
  screen = { "id": "screen" }

  m.expectOnce(plugin, "isScreenShowing", [], true)
  m.expectOnce(plugin, "getStringValue", ["screen_name", ""], "")
  m.expectOnce(m.vm, "createInstance", ["known"], screen)

  m.expectOnce(m.vm.pluginProvider, "getStartupPlugins", [], [plugin])

  m.expectOnce(m.vm, "bindNodeField", [screen, "state", "onPrehookStateChange", MOM.createBindingProperties(false, invalid, true)])
  m.expectOnce(m.vm, "push", [screen])
  m.expectOnce(m.vm, "setFocus", [screen])

  m.assertTrue(m.vm.showPreHookIfRequired())

  m.assertEqual(screen.id, "prehookScreen")
  m.assertEqual(m.vm.prehookScreen, screen)
  m.assertInvalid(m.vm.prehookScreen.riversJson)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests onPrehookStateChange
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function onPrehookStateChange_finished()
  state = "finished"
  m.vm.prehookScreen = { "id": "screen", "state": state }
  m.vm.startupPlugin = { "id": "startupPlugin" }
  m.expectOnce(m.vm, "pop")
  m.expectOnce(m.vm.startupPlugin, "saveFlag")

  m.vm.onPrehookStateChange(state)

  m.assertInvalid(m.prehookScreen)
  m.assertInvalid(m.startupPlugin)

end function

'@Test other states
'@Params["loading"]
'@Params["error"]
'@Params["other"]
function onPrehookStateChange_other(state)
  m.vm.prehookScreen = { "id": "screen", "state": state }
  m.vm.startupPlugin = { "id": "startupPlugin" }

  m.expectNone(m.vm, "pop")
  m.expectNone(m.vm.startupPlugin, "saveFlag")

  m.vm.onPrehookStateChange(state)

  m.assertNotInvalid(m.vm.prehookScreen)
  m.assertNotInvalid(m.vm.startupPlugin)

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests isDeeplinkingRequired
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function isDeeplinkingRequired()
  m.vm.isDeeplinkingRequired()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests processLiveDeeplinkingArgs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function processLiveDeeplinkingArgs()
  m.vm.processLiveDeeplinkingArgs()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests toggleDeeplinkingTask
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function toggleDeeplinkingTask()
  m.vm.toggleDeeplinkingTask()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests onDeeplinkingTaskResult
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function onDeeplinkingTaskResult()
  m.vm.onDeeplinkingTaskResult()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests enterDeeplinking
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function enterDeeplinking()
  m.vm.enterDeeplinking()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests exitFromDeeplinking
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function exitFromDeeplinking()
  m.vm.exitFromDeeplinking()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests toggleNavMenuFocus
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
'@Params[true, true, true, "topMenuBar"]
'@Params[true, false, false, "tabController"]
'@Params[false, true, false, "tabController"]
'@Params[false, false, false, "tabController"]
function toggleNavMenuFocus(isNavMenuVisible, isFocused, expectedFocusedValue, expectedFocusId)

  m.vm.isNavMenuVisible = isNavMenuVisible

  m.vm.toggleNavMenuFocus(isFocused)

  m.assertEqual(m.vm.isNavMenuFocused, expectedFocusedValue)
  m.assertEqual(m.vm.focusId, expectedFocusId)

end function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests toggleNavMenuVisible
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



'@Test
'@Params[true, false, true, true, false]
'@Params[true, true, true, true, true]
'@Params[false, false, false, false, false]
'@Params[false, true, false, false, true]
function toggleNavMenuVisible(isVisible, isLogoVisible, expectedMenuVisible, expectedBannerVisible, expectedLogoVisible)

  m.vm.toggleNavMenuVisible(isVisible, isLogoVisible)

  m.assertEqual(m.vm.menuVisibilitySettings.isMenuVisible, expectedMenuVisible)
  m.assertEqual(m.vm.menuVisibilitySettings.isMenuVisible, expectedMenuVisible)
  m.assertEqual(m.vm.menuVisibilitySettings.isMenuVisible, expectedMenuVisible)
  m.assertEqual(m.vm.menuVisibilitySettings.isMenuVisible, expectedMenuVisible)
  m.assertEqual(m.vm.menuVisibilitySettings.isTopBannerVisible, expectedBannerVisible)
  m.assertEqual(m.vm.menuVisibilitySettings.isLogoVisible, expectedLogoVisible)

end function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests navigateToHomeItem
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function navigateToHomeItem()
  m.vm.navMenuFocusIndex = 1
  m.vm.isHomeLoaded = false
  m.expectOnce(m.vm, "toggleNavMenuFocus", [true])
  m.expectOnce(m.vm, "signalAppLaunchComplete")
  m.expectOnce(m.vm, "showPreHookIfrequired", [])

  m.vm.navigateToHomeItem()

  m.assertTrue(m.vm.isHomeLoaded)
  m.assertEqual(m.vm.navMenuFocusIndex, 0)


end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests configureNavMenu
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function configureNavMenu_valid()
  homeScreen = {
    riversJson: {
      navigations: [
        { id: "n1" }
        { id: "n2" }
        { id: "n3" }
      ]
    }
  }

  m.expectOnce(m.vm, "getHomeScreen", [], homeScreen)

  m.vm.configureNavMenu()

  m.assertTrue(m.vm.isMenuCreated)
  m.assertEqual(m.vm.navMenuJson, homeScreen.riversJson.navigations[0])

end function

'@Test
'@Params[invalid]
'@Params[{riversJson:{navigations:[]}}]
function configureNavMenu_invalid(homeScreen)
  m.expectOnce(m.vm, "getHomeScreen", [], homeScreen)

  m.vm.configureNavMenu()

  m.assertTrue(m.vm.isMenuCreated)
  m.assertInvalid(m.vm.navMenuJson)

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests resetLoadingFlags
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function resetLoadingFlags()
  m.expectOnce(m.vm, "updateLoadingFlagsForCurrentView", [])

  m.vm.resetLoadingFlags()
  m.assertEmpty(m.vm.screenLoadingFlagsByScreenId)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests updateLoadingFlagsForCurrentView
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test appControllerLoading
function updateLoadingFlagsForCurrentView_appControllerIsLoading()
  m.vm.screenLoadingFlagsByScreenId = {
    "sid": true
    "sid2" : true
    "appController": true
  }
  m.expectOnce(m.vm, "toggleLoadingIndicator", [true])
  m.expectNone(m.vm, "getTopScreen")

  m.vm.updateLoadingFlagsForCurrentView()

end function

'@Test no top screen
'@Params[{"sid":true}, true]
'@Params[{}, false]
function updateLoadingFlagsForCurrentView_noTopScreen(screenLoadingFlags, expectedLoading)
  m.vm.screenLoadingFlagsByScreenId = screenLoadingFlags

  m.expectOnce(m.vm, "toggleLoadingIndicator", [expectedLoading])
  m.expectOnce(m.vm, "getTopScreen", [], invalid)

  m.vm.updateLoadingFlagsForCurrentView()

end function

'@Test no top screen
'@Params[{}, false]
'@Params[{"sid":true}, false]
'@Params[{"sid":true, "sid2": true}, true]
function updateLoadingFlagsForCurrentView_topScreen(screenLoadingFlags, expectedLoading)
  m.vm.screenLoadingFlagsByScreenId = screenLoadingFlags
  topScreen = { "id": "sid2" }

  m.expectOnce(m.vm, "toggleLoadingIndicator", [expectedLoading])
  m.expectOnce(m.vm, "getTopScreen", [], topScreen)

  m.vm.updateLoadingFlagsForCurrentView()

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests setScreenLoadingFlag
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
'@Params[invalid]
'@Params[""]
function setScreenLoadingFlag_invalidScreenI(screenId)

  m.vm.setScreenLoadingFlag(screenId, true)

  m.expectNone(m.vm, "updateLoadingFlagsForCurrentView")
end function

'@Test loading
function setScreenLoadingFlag_loading()

  m.expectOnce(m.vm, "updateLoadingFlagsForCurrentView", [])

  m.vm.setScreenLoadingFlag("sid", true)

  m.assertTrue(m.vm.screenLoadingFlagsByScreenId["sid"])

end function

'@Test not loading
function setScreenLoadingFlag_notLoading()

  m.expectOnce(m.vm, "updateLoadingFlagsForCurrentView", [])
  m.vm.screenLoadingFlagsByScreenId["sid"] = true

  m.vm.setScreenLoadingFlag("sid", false)
  m.assertAANotHasKey(m.vm.screenLoadingFlagsByScreenId, "sid")

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests toggleLoadingIndicator
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
'@Params[true, "start"]
'@Params[false, "stop"]
function toggleLoadingIndicator(isActive, control)

  m.vm.toggleLoadingIndicator(isActive)
  m.assertEqual(m.vm.loadingIndicatorControl, control)

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests playSelection
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test
function playSelection()
  selection = { "id": "selection" }
  m.expectOnce(m.vm, "toggleIsVideoPlayerVisible", [true])

  m.vm.playSelection(selection)
  m.assertEqual(m.vm.videoPlayerSelection, selection)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests toggleIsVideoPlayerVisible
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test visible
function toggleIsVideoPlayerVisible_visible()
  m.expectOnce(m.vm, "push", ["videoPlayer"])

  m.vm.toggleIsVideoPlayerVisible(true)

  m.assertTrue(m.vm.isVideoPlayerVisible)
  m.assertFalse(m.vm.topMenuBarVisible)
  m.assertEqual(m.vm.focusId, "videoPlayer")
end function

'@Test not visible
function toggleIsVideoPlayerVisible_not_visible()
  m.expectOnce(m.vm, "pop")

  m.vm.toggleIsVideoPlayerVisible(false)

  m.assertFalse(m.vm.isVideoPlayerVisible)
  m.assertTrue(m.vm.topMenuBarVisible)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests onVideoIsPlaybackFinishedChange
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test finished
function onVideoIsPlaybackFinishedChange()
  m.vm.isVideoPlayerVisible = true
  m.expectOnce(m.vm, "toggleVideoPlayerVisible", [false])

  m.vm.onVideoIsPlaybackFinishedChange(true)

end function

'@Test not finished
'@Params[false, false]
'@Params[false, true]
'@Params[true, false]
function onVideoIsPlaybackFinishedChange_noChange(isFinished, playerVisible)
  m.vm.isVideoPlayerVisible = playerVisible
  m.expectNone(m.vm, "toggleVideoPlayerVisible")

  m.vm.onVideoIsPlaybackFinishedChange(isFinished)

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests showOptionsMenu
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function showOptionsMenu()
  m.vm.showOptionsMenu()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests hideOptionsMenu
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function hideOptionsMenu()
  m.vm.hideOptionsMenu()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests onKeyPressDown
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test menu focus
function onKeyPressDown_onMenu()
  m.vm.focusId = "topMenuBar"
  m.expectOnce(m.vm, "toggleNavMenuFocus", [false])

  m.assertTrue(m.vm.onKeyPressDown())

end function

'@Test other focus
function onKeyPressDown_onOther()
  m.vm.focusId = "tabController"
  m.expectNone(m.vm, "toggleNavMenuFocus")

  m.assertFalse(m.vm.onKeyPressDown())

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests onKeyPressUp
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test show debug dialog
function onKeyPressUp_showDebugDialog()
  m.vm.debugMenuUpCount = 19
  m.expectNone(m.vm, "toggleNavMenuFocus")
  m.expectOnce(m.vm, "showDebugDialog", [])

  m.assertTrue(m.vm.onKeyPressUp())

end function

'@Test jump to menu
function onKeyPressUp_jumpToMenu()
  m.vm.focusId = "tabController"
  m.expectOnce(m.vm, "toggleNavMenuFocus", [true])
  m.expectNone(m.vm, "showDebugDialog")

  m.assertTrue(m.vm.onKeyPressUp())

end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests onKeyPressBack
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test back locked
'@Params[true, false, false]
'@Params[true, false, true]
'@Params[true, true, false]
'@Params[true, true, true]
'@Params[true, true, true]
function onKeyPressBack_locked(locked, isDeeplinking, navMenuFocused)
  m.expectNone(m.vm, "exitFromDeepLinking")
  m.expectNone(m.vm, "toggleNavMenuFocus")
  m.vm.isBackButtonLocked = locked
  m.vm.isInDeeplinkMode = isDeeplinking
  m.vm.isNavMenuFocused = navMenuFocused

  m.assertTrue(m.vm.onKeyPressBack())
end function

'@Test deeplinking
'@Params[true, false]
'@Params[true, true]
'@Params[true, false]
'@Params[true, true]
'@Params[true, true]
function onKeyPressBack_deepLinking(isDeeplinking, navMenuFocused)
  m.expectOnce(m.vm, "exitFromDeepLinking", [])
  m.expectNone(m.vm, "toggleNavMenuFocus")
  m.vm.isInDeeplinkMode = isDeeplinking
  m.vm.isNavMenuFocused = navMenuFocused

  m.assertTrue(m.vm.onKeyPressBack())
end function

'@Test navMenuFocused false
function onKeyPressBack_navMenuFocusedFalse()
  m.expectNone(m.vm, "exitFromDeepLinking")
  m.expectOnce(m.vm, "toggleNavMenuFocus", [true])
  m.vm.isNavMenuFocused = false

  m.assertFalse(m.vm.onKeyPressBack())
end function

'@Test navMenuFocused true
function onKeyPressBack_navMenuFocused_true()
  m.expectNone(m.vm, "exitFromDeepLinking")
  m.expectNone(m.vm, "toggleNavMenuFocus")
  m.vm.isNavMenuFocused = true

  m.assertFalse(m.vm.onKeyPressBack())
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests onKeyPressOption
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Ignore - not implemented yet
'@Test
function onKeyPressOption()
  m.vm.onKeyPressOption()

  m.fail("write a test for me!")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests isCapturingAnyKeyPress
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test isCapturingAnyKeyPress
'@Params["down", 0]
'@Params["left", 0]
'@Params["right", 0]
'@Params["up", 15]
function isCapturingAnyKeyPress(key, expectedDebugMenuCount)
  m.vm.debugMenuUpCount = 15

  m.assertFalse(m.vm.isCapturingAnyKeyPress(key, true))

  m.assertEqual(m.vm.debugMenuUpCount, expectedDebugMenuCount)
end function
end namespace