sub Main(args as dynamic)
    print "Launching with args "
    print args
    m.args = args

    if (type(Rooibos__Init) = "Function") then Rooibos__Init(args, SetupGlobals, "AddTestUtils")
    InitScreen()

    if testA = true and testB = true then
        a = false
        print "hello"
    end if

    if a = true then ? "hello" else ? "world"

    if a = true or b = true
        ? "firs"
    else if b = c
        ? "else if 1"
    else if a = false and c = true
        ? "else if 2"
    else
        ? "else"
    end if
end sub


function InitScreen() as void
    'this will be where you setup your typical roku app
    'it will not be launched when running unit tests
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    rootScene = screen.CreateScene("MainScene")
    rootScene.id = "ROOT"
    
    screen.show()

    SetupGlobals(screen)
    if gotoTest = true
      goto gotoTestLabel
    end if

    gotoTestLabel:

    'demonstrate code coverage in nested functions
    nestedAA = {
        someValue: {
            _fun1: function(arg1, arg2)
                a = 12
                if a = 12
                    ? "12"
                else
                    ? "not 12"
                end if
            end function
            otherValue: "b"
        }
    }

    nestedAA["AAset"] = function()
        ? "test"
    end function

    funcs = [
    "no",
    function()
        ? "test"
    end function,
    "yes"
    ]

    funcs[0] = function()
       ? "test"
    end function
    m.callThisWithFunction(function()
                                  ? "test"
                               end function)
    callThisWithFunction(function()
                                                           ? "test"
                                                        end function)

    testFunction =function(arg1, arg2)
          a = 12
          if a = 12
              ? "12"
          else
              ? "not 12"
          end if
      end function

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
      
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() 
                return
            end if
        end if
    end while
end function


'*************************************************************
'** SetupGlobals
'** @param screen as roScreen - screen to set globals on
'*************************************************************
function SetupGlobals(screen) as void
    print "SETTTING UP GLOBALS - do your standard setup stuff here"

    m.global = screen.getGlobalNode()

    m.roDeviceInfo = CreateObject("roDeviceInfo")
    
    m.displayInfo = {
        resolution: m.roDeviceInfo.GetUIResolution() 
        displayType: m.roDeviceInfo.GetDisplayType() 
        width: m.roDeviceInfo.GetDisplaySize().w
        height: m.roDeviceInfo.GetDisplaySize().h
        wFactor: m.roDeviceInfo.GetDisplaySize().w/1920
        hFactor: m.roDeviceInfo.GetDisplaySize().h/1080
    }

    m.modelLocator = {"displayInfo":m.displayInfo} ' contrived example : this would be a specifc modelLocator node/other setup thing

    m.global.addFields({"modelLocator": m.modelLocator})
end function

