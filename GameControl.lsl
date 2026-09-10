vector baseTint   = <0.051, 0.051, 0.051>;
vector activeTint = <0.2, 0.2, 1.0>;

integer previousMask;
list    buttonMap;  
integer buttonCount;
list    axisLinks;  

vector mixColor(vector a, vector b, float t) {
    return a + (b - a) * t;
}

integer FindLinkByName(string linkName) {
    integer start = (llGetLinkNumber() != 0);
    integer total = llGetNumberOfPrims() + start;
    integer idx;
    for (idx = start; idx < total; ++idx)
        if (llGetLinkName(idx) == linkName)
            return idx;
    return -199;
}

list ButtonUpdate(integer link, vector tint) {
    return [
        PRIM_LINK_TARGET, link,
            PRIM_COLOR, ALL_SIDES, tint, 1.0,
            PRIM_GLTF_BASE_COLOR, ALL_SIDES, "", "", "", "", tint, 1.0, "", "", ""
    ];
}

list StickUpdate(integer link, vector tint, float pitchDeg, float rollDeg) {
    return ButtonUpdate(link, tint) + [
        PRIM_ROT_LOCAL, llEuler2Rot(<pitchDeg, rollDeg, 0.0> * DEG_TO_RAD)
    ];
}

default {
    state_entry() {
        buttonMap = [
            GAME_CONTROL_BUTTON_A,             FindLinkByName("btn.a"),
            GAME_CONTROL_BUTTON_B,             FindLinkByName("btn.b"),
            GAME_CONTROL_BUTTON_X,             FindLinkByName("btn.x"),
            GAME_CONTROL_BUTTON_Y,             FindLinkByName("btn.y"),
            GAME_CONTROL_BUTTON_BACK,          FindLinkByName("back"),
            GAME_CONTROL_BUTTON_GUIDE,         FindLinkByName("guide"),
            GAME_CONTROL_BUTTON_START,         FindLinkByName("start"),
            GAME_CONTROL_BUTTON_LEFTSTICK,     FindLinkByName("stick.left"),
            GAME_CONTROL_BUTTON_RIGHTSTICK,    FindLinkByName("stick.right"),
            GAME_CONTROL_BUTTON_LEFTSHOULDER,  FindLinkByName("shoulder.left"),
            GAME_CONTROL_BUTTON_RIGHTSHOULDER, FindLinkByName("shoulder.right"),
            GAME_CONTROL_BUTTON_DPAD_UP,       FindLinkByName("dpad.up"),
            GAME_CONTROL_BUTTON_DPAD_DOWN,     FindLinkByName("dpad.down"),
            GAME_CONTROL_BUTTON_DPAD_LEFT,     FindLinkByName("dpad.left"),
            GAME_CONTROL_BUTTON_DPAD_RIGHT,    FindLinkByName("dpad.right"),
            GAME_CONTROL_BUTTON_MISC1,         FindLinkByName("misc"),
            GAME_CONTROL_BUTTON_PADDLE1,       FindLinkByName("paddle.1"),
            GAME_CONTROL_BUTTON_PADDLE2,       FindLinkByName("paddle.2"),
            GAME_CONTROL_BUTTON_PADDLE3,       FindLinkByName("paddle.3"),
            GAME_CONTROL_BUTTON_PADDLE4,       FindLinkByName("paddle.4"),
            GAME_CONTROL_BUTTON_TOUCHPAD,      FindLinkByName("touchpad")
        ];
        buttonCount = llGetListLength(buttonMap) / 2;

        axisLinks = [
            FindLinkByName("stick.left"),   FindLinkByName("stick.left"),
            FindLinkByName("stick.right"),  FindLinkByName("stick.right"),
            FindLinkByName("trigger.left"), FindLinkByName("trigger.right")
        ];

        integer i;
        for (i = 0; i < buttonCount; ++i)
            if (llList2Integer(buttonMap, i * 2 + 1) == -199)
                llOwnerSay("WARNING: no prim named for button #" + (string)i);
        for (i = 0; i < 6; ++i)
            if (llList2Integer(axisLinks, i) == -199)
                llOwnerSay("WARNING: no prim named for axis #" + (string)i);

        llOwnerSay("Gamepad HUD ready.");

        if (llGetAttached())
            llRequestPermissions(llGetOwner(), PERMISSION_GAME_CONTROL);
    }

    attach(key id) {
        if (id) {
            llOwnerSay("Gamepad HUD attached, requesting permissions...");
            llRequestPermissions(id, PERMISSION_GAME_CONTROL);
        }
    }

    run_time_permissions(integer perm) {
        if (perm & PERMISSION_GAME_CONTROL)
            llOwnerSay("PERMISSION_GAME_CONTROL granted.");
        else
            llOwnerSay("WARNING: PERMISSION_GAME_CONTROL denied - game_control will never fire.");
    }

    game_control(key id, integer mask, list axisValues) {
        integer changedMask = mask ^ previousMask;
        previousMask = mask;

        float lx = llList2Float(axisValues, GAME_CONTROL_AXIS_LEFTX);
        float ly = llList2Float(axisValues, GAME_CONTROL_AXIS_LEFTY);
        float rx = llList2Float(axisValues, GAME_CONTROL_AXIS_RIGHTX);
        float ry = llList2Float(axisValues, GAME_CONTROL_AXIS_RIGHTY);
        float tl = llList2Float(axisValues, GAME_CONTROL_AXIS_TRIGGERLEFT);
        float tr = llList2Float(axisValues, GAME_CONTROL_AXIS_TRIGGERRIGHT);

        list updates = [];
        updates += StickUpdate(llList2Integer(axisLinks, GAME_CONTROL_AXIS_LEFTX),
            mixColor(baseTint, activeTint, llListStatistics(LIST_STAT_MAX, [llFabs(lx), llFabs(ly)])),
            ly * 30.0, lx * 30.0);
        updates += StickUpdate(llList2Integer(axisLinks, GAME_CONTROL_AXIS_RIGHTX),
            mixColor(baseTint, activeTint, llListStatistics(LIST_STAT_MAX, [llFabs(rx), llFabs(ry)])),
            ry * 30.0, rx * 30.0);
        updates += ButtonUpdate(llList2Integer(axisLinks, GAME_CONTROL_AXIS_TRIGGERLEFT),
            mixColor(baseTint, activeTint, tl));
        updates += ButtonUpdate(llList2Integer(axisLinks, GAME_CONTROL_AXIS_TRIGGERRIGHT),
            mixColor(baseTint, activeTint, tr));

        integer i;
        for (i = 0; i < buttonCount; ++i) {
            integer btnConst = llList2Integer(buttonMap, i * 2);
            integer link     = llList2Integer(buttonMap, i * 2 + 1);
            if (mask & btnConst)
                updates += ButtonUpdate(link, activeTint);
            else if (changedMask & btnConst)
                updates += ButtonUpdate(link, baseTint);
        }

        llSetLinkPrimitiveParamsFast(LINK_SET, updates);
    }
}
