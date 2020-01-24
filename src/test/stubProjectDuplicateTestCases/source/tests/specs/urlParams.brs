'@TestSuite [SS] SoloSuite

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It urlTests
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test withUrl
'@Params[{isClip:false}, {type:"http://101.rooibos.com"}, "show"]
function UT_withUrl(videoType, returnedJson, typeName) as void
  getjsonMock = m.expectOnce(m.httpService, "getJson", [m.ignoreValue, videoType], returnedJson, true)

  videos = m.module.getVideosRealExample(videoType)

  m.AssertArrayContainsSubset(videos, returnedJson)
end function

'@Test withUrlThatFailed for me
function UT_withUrl(videoType, returnedJson, typeName) as void
  getjsonMock = m.expectOnce(m.httpService, "getJson", [m.ignoreValue, videoType], returnedJson, true)

  videos = m.module.getVideosRealExample(videoType)

  m.AssertArrayContainsSubset(videos, returnedJson)
end function