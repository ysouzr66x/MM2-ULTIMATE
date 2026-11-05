--[[
╔══════════════════════════════════════════╗
║        MM2 ULTIMATE — by Leonardo        ║
║         Botão Flutuante: UK1N            ║
║      DEVELOPED BY LEONARDO               ║
║      Delta Executor | Lua 5.1            ║
╚══════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")

local lp   = Players.LocalPlayer
local cam  = workspace.CurrentCamera

local function getChar()  return lp.Character end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()   local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ═══════════════════════════════════════
--  THEME
-- ═══════════════════════════════════════
local T = {
    -- glassmorphism base
    glass      = Color3.fromRGB(12, 10, 20),
    glassBrd   = Color3.fromRGB(80, 50, 120),
    glassCard  = Color3.fromRGB(18, 14, 30),

    -- accents (default purple-neon, overridable)
    accent     = Color3.fromRGB(160, 50, 255),
    accentDim  = Color3.fromRGB(90, 20, 160),
    accentNeon = Color3.fromRGB(200, 80, 255),
    accentGlow = Color3.fromRGB(120, 30, 200),

    -- text
    textPri    = Color3.fromRGB(240, 235, 255),
    textSec    = Color3.fromRGB(150, 140, 175),
    textDim    = Color3.fromRGB(80, 70, 100),

    -- status
    green      = Color3.fromRGB(50, 220, 100),
    red        = Color3.fromRGB(220, 50, 80),
    cyan       = Color3.fromRGB(50, 220, 230),
    yellow     = Color3.fromRGB(240, 200, 50),

    black      = Color3.fromRGB(0, 0, 0),
    white      = Color3.fromRGB(255, 255, 255),
}

-- ═══════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════
local S = {
    open = false,
    tab  = "PLAYER",
    accentKey = "purple",

    -- PLAYER
    walkSpeed    = 16,
    speedOn      = false,
    jumpPower    = 50,
    jumpOn       = false,
    infJump      = false,
    flyOn        = false,
    noclipOn     = false,

    -- ESP
    espPlayers   = false,
    espMurderer  = false,
    espSheriff   = false,
    espInnocent  = false,
    espItems     = false,
    espCoins     = false,
    espNames     = false,
    espDist      = false,
    espColorPlr  = Color3.fromRGB(255,255,255),
    espColorMurd = Color3.fromRGB(220,50,80),
    espColorSher = Color3.fromRGB(50,180,255),
    espColorInn  = Color3.fromRGB(50,220,100),

    -- COMBAT
    aimKill      = false,
    aimbot       = false,
    targetESP    = false,

    -- VISUAL
    fullbright   = false,
    noFog        = false,
    brightness   = 1,
    fov          = 70,
    bgAlpha      = 0.75,
    uiScale      = 1,

    -- FARM
    farmCoins    = false,
    farmItems    = false,
    coinCount    = 0,
    itemCount    = 0,
    coinTime     = 0,
    itemTime     = 0,
    coinStart    = 0,
    itemStart    = 0,
    farmStatus   = "STOPPED",
    sessionLog   = {},
}

-- ═══════════════════════════════════════
--  ACCENT COLORS MAP
-- ═══════════════════════════════════════
local ACCENTS = {
    red    = {main=Color3.fromRGB(220,40,60),   neon=Color3.fromRGB(255,60,80)},
    purple = {main=Color3.fromRGB(160,50,255),  neon=Color3.fromRGB(200,80,255)},
    blue   = {main=Color3.fromRGB(50,100,255),  neon=Color3.fromRGB(80,140,255)},
    green  = {main=Color3.fromRGB(40,200,100),  neon=Color3.fromRGB(60,240,120)},
    pink   = {main=Color3.fromRGB(255,60,180),  neon=Color3.fromRGB(255,100,210)},
    white  = {main=Color3.fromRGB(220,220,235), neon=Color3.fromRGB(255,255,255)},
    cyan   = {main=Color3.fromRGB(40,220,230),  neon=Color3.fromRGB(60,255,255)},
}

local function applyAccent(key)
    local a = ACCENTS[key] or ACCENTS.purple
    T.accent     = a.main
    T.accentNeon = a.neon
    T.accentDim  = Color3.fromRGB(
        math.floor(a.main.R*255*0.5),
        math.floor(a.main.G*255*0.5),
        math.floor(a.main.B*255*0.5)
    )
    S.accentKey = key
end

-- ═══════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════
local function newInst(cls, props)
    local i = Instance.new(cls)
    for k,v in pairs(props) do i[k]=v end
    return i
end

local function corner(parent, px)
    return newInst("UICorner",{CornerRadius=UDim.new(0,px or 12),Parent=parent})
end

local function stroke(parent, color, thick)
    return newInst("UIStroke",{
        Color=color or T.glassBrd,
        Thickness=thick or 1,
        Transparency=0.3,
        Parent=parent
    })
end

local function gradient(parent, c0, c1, rotation)
    local g = newInst("UIGradient",{
        Color=ColorSequence.new(c0 or T.glass, c1 or T.glassCard),
        Rotation=rotation or 135,
        Parent=parent
    })
    return g
end

local function tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.2,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function fmt(secs)
    local s=math.floor(secs)
    return string.format("%02d:%02d:%02d",
        math.floor(s/3600), math.floor((s%3600)/60), s%60)
end

-- ═══════════════════════════════════════
--  SCREEN GUI
-- ═══════════════════════════════════════
-- destroy old instance if reloading
local oldGui = lp:FindFirstChild("PlayerGui") and
               lp.PlayerGui:FindFirstChild("MM2_Ultimate")
if oldGui then oldGui:Destroy() end

local SG = newInst("ScreenGui",{
    Name="MM2_Ultimate",
    ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    Parent=lp:WaitForChild("PlayerGui")
})

local vp = cam.ViewportSize

-- ═══════════════════════════════════════
--  FLOATING BUTTON — UK1N
-- ═══════════════════════════════════════
local FAB_SZ = 62

local FABWrap = newInst("Frame",{
    Name="FAB",
    Size=UDim2.new(0,FAB_SZ+20,0,FAB_SZ+20),
    Position=UDim2.new(0, vp.X-FAB_SZ-30, 0.5,-FAB_SZ/2),
    BackgroundTransparency=1,
    ZIndex=50,
    Parent=SG
})

-- glow ring
local FABGlow = newInst("Frame",{
    Size=UDim2.new(0,FAB_SZ+16,0,FAB_SZ+16),
    Position=UDim2.new(0.5,-(FAB_SZ+16)/2, 0.5,-(FAB_SZ+16)/2),
    BackgroundColor3=T.accent,
    BackgroundTransparency=0.6,
    ZIndex=50,
    Parent=FABWrap
})
corner(FABGlow,40)

local FAB = newInst("Frame",{
    Size=UDim2.new(0,FAB_SZ,0,FAB_SZ),
    Position=UDim2.new(0.5,-FAB_SZ/2, 0.5,-FAB_SZ/2),
    BackgroundColor3=T.glass,
    ZIndex=51,
    Parent=FABWrap
})
corner(FAB,FAB_SZ/2)
stroke(FAB,T.accent,2)
gradient(FAB, Color3.fromRGB(20,14,38), Color3.fromRGB(8,6,18))

local FABLabel = newInst("TextLabel",{
    Size=UDim2.new(1,0,0,26),
    Position=UDim2.new(0,0,0.5,-16),
    Text="UK1N",
    TextColor3=T.textPri,
    TextSize=14,
    Font=Enum.Font.GothamBold,
    BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=52,
    Parent=FAB
})

local FABDot = newInst("Frame",{
    Size=UDim2.new(0,8,0,8),
    Position=UDim2.new(0.5,-4,1,-16),
    BackgroundColor3=T.accentNeon,
    ZIndex=52,
    Parent=FAB
})
corner(FABDot,4)

local FABBtn = newInst("TextButton",{
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1,
    Text="",
    ZIndex=53,
    Parent=FABWrap
})

-- pulsation
local fabPulse = true
task.spawn(function()
    while fabPulse do
        tween(FABGlow,{BackgroundTransparency=0.75},1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        task.wait(1.2)
        tween(FABGlow,{BackgroundTransparency=0.45},1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        task.wait(1.2)
    end
end)

-- drag
local fabDrag, fabDS, fabSP = false, nil, nil
FABBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or
       i.UserInputType==Enum.UserInputType.Touch then
        fabDrag=true
        fabDS=Vector2.new(i.Position.X,i.Position.Y)
        fabSP=FABWrap.Position
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or
       i.UserInputType==Enum.UserInputType.Touch then
        fabDrag=false
    end
end)
local fabMoved = false
UserInputService.InputChanged:Connect(function(i)
    if fabDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or
                    i.UserInputType==Enum.UserInputType.Touch) then
        local d=Vector2.new(i.Position.X,i.Position.Y)-fabDS
        if d.Magnitude>5 then fabMoved=true end
        FABWrap.Position=UDim2.new(
            fabSP.X.Scale, fabSP.X.Offset+d.X,
            fabSP.Y.Scale, fabSP.Y.Offset+d.Y)
    end
end)

-- ═══════════════════════════════════════
--  MAIN WINDOW
-- ═══════════════════════════════════════
local WIN_W = 360
local WIN_H = 520
local WIN_X = math.floor((vp.X-WIN_W)/2)
local WIN_Y = math.floor((vp.Y-WIN_H)/2)

-- shadow
local Shadow = newInst("Frame",{
    Size=UDim2.new(0,WIN_W+24,0,WIN_H+24),
    Position=UDim2.new(0,WIN_X-12,0,WIN_Y-12),
    BackgroundColor3=T.black,
    BackgroundTransparency=0.4,
    ZIndex=8,
    Visible=false,
    Parent=SG
})
corner(Shadow,22)

-- main
local Win = newInst("Frame",{
    Name="Win",
    Size=UDim2.new(0,WIN_W,0,WIN_H),
    Position=UDim2.new(0,WIN_X,0,WIN_Y),
    BackgroundColor3=T.glass,
    BackgroundTransparency=1-S.bgAlpha,
    ZIndex=9,
    Visible=false,
    Parent=SG
})
corner(Win,16)
stroke(Win,T.glassBrd,1.2)

-- glass gradient
gradient(Win,
    Color3.fromRGB(22,16,40),
    Color3.fromRGB(8,6,18), 145)

-- top neon line
local TopLine = newInst("Frame",{
    Size=UDim2.new(0.7,0,0,2),
    Position=UDim2.new(0.15,0,0,0),
    BackgroundColor3=T.accent,
    BackgroundTransparency=0.1,
    ZIndex=12,
    Parent=Win
})
corner(TopLine,1)

-- ═══════════════════════════════════════
--  HEADER
-- ═══════════════════════════════════════
local HDR_H = 54
local Hdr = newInst("Frame",{
    Size=UDim2.new(1,0,0,HDR_H),
    BackgroundColor3=Color3.fromRGB(10,8,22),
    BackgroundTransparency=0.1,
    ZIndex=10,
    Parent=Win
})
corner(Hdr,16)
-- bottom square corners
newInst("Frame",{
    Size=UDim2.new(1,0,0.5,0),
    Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(10,8,22),
    BackgroundTransparency=0.1,
    ZIndex=10,Parent=Hdr,BorderSizePixel=0
})

-- logo
newInst("TextLabel",{
    Size=UDim2.new(0,60,1,0),Position=UDim2.new(0,14,0,0),
    Text="MM2",TextColor3=T.textPri,TextSize=20,
    Font=Enum.Font.GothamBold,BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=Hdr
})
local LogoAccent = newInst("TextLabel",{
    Size=UDim2.new(0,120,0,16),Position=UDim2.new(0,14,0,32),
    Text="ULTIMATE",TextColor3=T.accent,TextSize=10,
    Font=Enum.Font.GothamBold,BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=Hdr
})

-- version dot
newInst("Frame",{
    Size=UDim2.new(0,8,0,8),
    Position=UDim2.new(0,86,0,22),
    BackgroundColor3=T.accentNeon,
    ZIndex=11,Parent=Hdr
})

-- close / min
local function hdrBtn(txt, xOff, clr)
    local b = newInst("TextButton",{
        Size=UDim2.new(0,30,0,30),
        Position=UDim2.new(1,xOff,0.5,-15),
        Text=txt,TextColor3=T.textSec,TextSize=14,
        Font=Enum.Font.GothamBold,
        BackgroundColor3=clr or Color3.fromRGB(30,24,50),
        ZIndex=11,Parent=Hdr,AutoButtonColor=false
    })
    corner(b,8)
    return b
end
local CloseBtn = hdrBtn("✕",-44, Color3.fromRGB(80,16,30))
local MinBtn   = hdrBtn("—",-82)

-- header drag
local winDrag,winDS,winSP=false,nil,nil
Hdr.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or
       i.UserInputType==Enum.UserInputType.Touch then
        winDrag=true; winDS=Vector2.new(i.Position.X,i.Position.Y); winSP=Win.Position
    end
end)
Hdr.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or
       i.UserInputType==Enum.UserInputType.Touch then winDrag=false end
end)
UserInputService.InputChanged:Connect(function(i)
    if winDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or
                    i.UserInputType==Enum.UserInputType.Touch) then
        local d=Vector2.new(i.Position.X,i.Position.Y)-winDS
        local np=UDim2.new(winSP.X.Scale,winSP.X.Offset+d.X,
                            winSP.Y.Scale,winSP.Y.Offset+d.Y)
        Win.Position=np
        Shadow.Position=UDim2.new(np.X.Scale,np.X.Offset-12,np.Y.Scale,np.Y.Offset-12)
    end
end)

-- ═══════════════════════════════════════
--  TAB BAR
-- ═══════════════════════════════════════
local TABS = {"PLAYER","ESP","VISUAL","FARM","COLOR","CONFIG"}
local TAB_ICONS = {
    PLAYER="⚡", ESP="👁", VISUAL="✦", FARM="⬟", COLOR="◈", CONFIG="⚙"
}
local TAB_H = 46
local TabBar = newInst("Frame",{
    Size=UDim2.new(1,0,0,TAB_H),
    Position=UDim2.new(0,0,0,HDR_H),
    BackgroundColor3=Color3.fromRGB(8,6,18),
    BackgroundTransparency=0.05,
    ZIndex=10,Parent=Win,BorderSizePixel=0
})

-- tab separator line
newInst("Frame",{
    Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=T.glassBrd,BackgroundTransparency=0.5,
    ZIndex=11,Parent=TabBar,BorderSizePixel=0
})

local tabW = math.floor(WIN_W/#TABS)
local tabBtns = {}
local tabLines = {}

for i,name in ipairs(TABS) do
    local btn = newInst("TextButton",{
        Size=UDim2.new(0,tabW,1,0),
        Position=UDim2.new(0,(i-1)*tabW,0,0),
        Text=(TAB_ICONS[name] or "").."\n"..name,
        TextColor3=T.textDim,
        TextSize=9,
        Font=Enum.Font.GothamBold,
        BackgroundTransparency=1,
        ZIndex=11,Parent=TabBar,
        AutoButtonColor=false,
        TextWrapped=false,
        LineHeight=1.1,
    })

    local ul = newInst("Frame",{
        Size=UDim2.new(0,tabW-16,0,2),
        Position=UDim2.new(0,(i-1)*tabW+8,1,-2),
        BackgroundColor3=T.accent,
        BackgroundTransparency=1,
        ZIndex=12,Parent=TabBar,BorderSizePixel=0
    })
    corner(ul,1)

    tabBtns[name]=btn
    tabLines[name]=ul
end

-- ═══════════════════════════════════════
--  SCROLL AREA
-- ═══════════════════════════════════════
local SCROLL_Y = HDR_H + TAB_H + 1
local SCROLL_H = WIN_H - SCROLL_Y - 22

local Scroll = newInst("ScrollingFrame",{
    Size=UDim2.new(1,-4,0,SCROLL_H),
    Position=UDim2.new(0,2,0,SCROLL_Y),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ScrollBarThickness=3,
    ScrollBarImageColor3=T.accent,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=10,Parent=Win
})
local SL = newInst("UIListLayout",{
    SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,6),
    Parent=Scroll
})
newInst("UIPadding",{
    PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),
    PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),
    Parent=Scroll
})

-- ═══════════════════════════════════════
--  FOOTER
-- ═══════════════════════════════════════
newInst("TextLabel",{
    Size=UDim2.new(1,0,0,20),
    Position=UDim2.new(0,0,1,-22),
    Text="DEVELOPED BY LEONARDO",
    TextColor3=T.textDim,TextSize=9,
    Font=Enum.Font.Gotham,
    BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=10,Parent=Win
})

-- ═══════════════════════════════════════
--  CARD BUILDERS
-- ═══════════════════════════════════════
local function clearScroll()
    for _,c in ipairs(Scroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
end

local function mkSection(title, sub)
    local h = newInst("Frame",{
        Size=UDim2.new(1,0,0,32),
        BackgroundTransparency=1,
        ZIndex=11,Parent=Scroll
    })
    local accent = newInst("Frame",{
        Size=UDim2.new(0,3,0,20),Position=UDim2.new(0,0,0.5,-10),
        BackgroundColor3=T.accent,ZIndex=12,Parent=h,BorderSizePixel=0
    })
    corner(accent,2)
    newInst("TextLabel",{
        Size=UDim2.new(0.6,0,1,0),Position=UDim2.new(0,10,0,0),
        Text=title,TextColor3=T.textPri,TextSize=13,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=h
    })
    if sub then
        newInst("TextLabel",{
            Size=UDim2.new(0.4,0,1,0),Position=UDim2.new(0.6,0,0,0),
            Text=sub,TextColor3=T.textDim,TextSize=10,
            Font=Enum.Font.Gotham,BackgroundTransparency=1,
            TextXAlignment=Enum.TextXAlignment.Right,ZIndex=12,Parent=h
        })
    end
    return h
end

-- glassmorphism card
local function mkCard(h)
    local card = newInst("Frame",{
        Size=UDim2.new(1,0,0,h or 64),
        BackgroundColor3=T.glassCard,
        BackgroundTransparency=0.15,
        ZIndex=11,Parent=Scroll
    })
    corner(card,12)
    stroke(card,T.glassBrd,1)
    gradient(card,Color3.fromRGB(24,18,44),Color3.fromRGB(14,10,28),160)
    return card
end

-- toggle card
local function mkToggle(title, desc, initVal, onChange)
    local card = mkCard(66)
    newInst("TextLabel",{
        Size=UDim2.new(0.72,0,0,22),Position=UDim2.new(0,14,0,10),
        Text=title,TextColor3=T.textPri,TextSize=13,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=card
    })
    newInst("TextLabel",{
        Size=UDim2.new(0.72,0,0,18),Position=UDim2.new(0,14,0,32),
        Text=desc,TextColor3=T.textSec,TextSize=11,
        Font=Enum.Font.Gotham,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=card
    })

    local track = newInst("Frame",{
        Size=UDim2.new(0,52,0,28),
        Position=UDim2.new(1,-66,0.5,-14),
        BackgroundColor3=initVal and T.accent or T.textDim,
        ZIndex=12,Parent=card
    })
    corner(track,14)
    local knob = newInst("Frame",{
        Size=UDim2.new(0,22,0,22),
        Position=initVal and UDim2.new(1,-26,0.5,-11) or UDim2.new(0,4,0.5,-11),
        BackgroundColor3=T.white,ZIndex=13,Parent=track
    })
    corner(knob,11)

    local on = initVal
    local hit = newInst("TextButton",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text="",ZIndex=14,Parent=track
    })
    hit.MouseButton1Click:Connect(function()
        on=not on
        tween(track,{BackgroundColor3=on and T.accent or T.textDim},0.15)
        tween(knob,{Position=on and UDim2.new(1,-26,0.5,-11) or UDim2.new(0,4,0.5,-11)},0.15)
        if onChange then onChange(on) end
    end)
    return card
end

-- slider card
local function mkSlider(title, desc, minV, maxV, defV, onChange)
    local card = mkCard(80)
    newInst("TextLabel",{
        Size=UDim2.new(0.7,0,0,20),Position=UDim2.new(0,14,0,8),
        Text=title,TextColor3=T.textPri,TextSize=13,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=card
    })
    newInst("TextLabel",{
        Size=UDim2.new(0.7,0,0,16),Position=UDim2.new(0,14,0,26),
        Text=desc,TextColor3=T.textSec,TextSize=10,
        Font=Enum.Font.Gotham,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=card
    })
    local valLbl = newInst("TextLabel",{
        Size=UDim2.new(0.3,0,0,20),Position=UDim2.new(0.7,-14,0,8),
        Text=tostring(defV),TextColor3=T.accentNeon,TextSize=15,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=12,Parent=card
    })

    local track = newInst("Frame",{
        Size=UDim2.new(1,-28,0,4),Position=UDim2.new(0,14,0,55),
        BackgroundColor3=T.textDim,ZIndex=12,Parent=card
    })
    corner(track,2)
    local pct0=(defV-minV)/(maxV-minV)
    local fill = newInst("Frame",{
        Size=UDim2.new(pct0,0,1,0),BackgroundColor3=T.accent,
        ZIndex=13,Parent=track,BorderSizePixel=0
    })
    corner(fill,2)
    local knob = newInst("Frame",{
        Size=UDim2.new(0,16,0,16),
        Position=UDim2.new(pct0,0,0.5,-8),
        BackgroundColor3=T.white,ZIndex=14,Parent=track
    })
    corner(knob,8)
    -- shadow on knob
    stroke(knob,T.accent,2)

    local cur=defV; local sdrag=false
    local hit2=newInst("TextButton",{
        Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0.5,-16),
        BackgroundTransparency=1,Text="",ZIndex=15,Parent=track
    })
    hit2.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or
           i.UserInputType==Enum.UserInputType.Touch then sdrag=true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or
           i.UserInputType==Enum.UserInputType.Touch then sdrag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sdrag and (i.UserInputType==Enum.UserInputType.MouseMovement or
                      i.UserInputType==Enum.UserInputType.Touch) then
            local abs=track.AbsoluteSize.X; if abs==0 then return end
            local relX=math.clamp(i.Position.X-track.AbsolutePosition.X,0,abs)
            local p=relX/abs
            cur=math.floor(minV+p*(maxV-minV))
            fill.Size=UDim2.new(p,0,1,0)
            knob.Position=UDim2.new(p,0,0.5,-8)
            valLbl.Text=tostring(cur)
            if onChange then onChange(cur) end
        end
    end)
    return card
end

-- action button
local function mkAction(text, color, onClick)
    local card=mkCard(50)
    card.BackgroundColor3=color or T.accentDim
    card.BackgroundTransparency=0.05
    newInst("TextLabel",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text=text,TextColor3=T.textPri,TextSize=13,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=12,Parent=card
    })
    local h=newInst("TextButton",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text="",ZIndex=13,Parent=card
    })
    h.MouseButton1Click:Connect(function()
        tween(card,{BackgroundTransparency=0.4},0.08)
        task.delay(0.08,function() tween(card,{BackgroundTransparency=0.05},0.08) end)
        if onClick then onClick() end
    end)
    return card
end

-- stat card
local function mkStat(label, valRef, color)
    local card=mkCard(72)
    newInst("TextLabel",{
        Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,14,0,8),
        Text=label,TextColor3=T.textSec,TextSize=11,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=card
    })
    local vl=newInst("TextLabel",{
        Size=UDim2.new(1,-14,0,34),Position=UDim2.new(0,14,0,28),
        Text=valRef or "00:00:00",TextColor3=color or T.accentNeon,TextSize=28,
        Font=Enum.Font.Code,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=card
    })
    return card, vl
end

-- ═══════════════════════════════════════
--  FLIGHT ENGINE
-- ═══════════════════════════════════════
local flyConn
local function startFly()
    local hrp=getHRP(); if not hrp then return end
    local bv=Instance.new("BodyVelocity")
    bv.Name="MM2_FlyBV"; bv.MaxForce=Vector3.new(1e5,1e5,1e5)
    bv.Velocity=Vector3.new(0,0,0); bv.Parent=hrp
    local bg=Instance.new("BodyGyro")
    bg.Name="MM2_FlyBG"; bg.MaxTorque=Vector3.new(0,4e5,0)
    bg.P=1e4; bg.Parent=hrp
    flyConn=RunService.RenderStepped:Connect(function()
        local h=getHRP(); if not h then return end
        local bv2=h:FindFirstChild("MM2_FlyBV")
        if not bv2 then return end
        local spd=50; local vel=Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel+=cam.CFrame.LookVector*spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel-=cam.CFrame.LookVector*spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel-=cam.CFrame.RightVector*spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel+=cam.CFrame.RightVector*spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel+=Vector3.new(0,spd,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel-=Vector3.new(0,spd,0) end
        bv2.Velocity=vel
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    local hrp=getHRP(); if not hrp then return end
    local bv=hrp:FindFirstChild("MM2_FlyBV"); if bv then bv:Destroy() end
    local bg=hrp:FindFirstChild("MM2_FlyBG"); if bg then bg:Destroy() end
end

-- infinite jump
local ijConn
lp.CharacterAdded:Connect(function(c)
    local h=c:WaitForChild("Humanoid")
    h.StateChanged:Connect(function(_,new)
        if S.infJump and new==Enum.HumanoidStateType.Jumping then
            task.wait(0.1); h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end)

-- noclip
local ncConn
local function startNoclip()
    ncConn=RunService.Stepped:Connect(function()
        local c=getChar(); if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end
local function stopNoclip()
    if ncConn then ncConn:Disconnect(); ncConn=nil end
    local c=getChar(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=true end
    end
end

-- ═══════════════════════════════════════
--  ESP ENGINE
-- ═══════════════════════════════════════
local espDrawings={}

local function getRoleColor(plr)
    local ok,role=pcall(function()
        return plr.Character and plr.Character:FindFirstChild("Role") and
               plr.Character.Role.Value or ""
    end)
    local r=ok and role or ""
    if r=="Murderer" then return S.espColorMurd
    elseif r=="Sheriff" then return S.espColorSher
    else return S.espColorInn end
end

local function cleanESP(uid)
    local d=espDrawings[uid]; if not d then return end
    for _,v in pairs(d) do pcall(function() v:Remove() end) end
    espDrawings[uid]=nil
end

local function rebuildESP()
    for uid,_ in pairs(espDrawings) do cleanESP(uid) end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=lp then
            local d={}
            if S.espPlayers or S.espMurderer or S.espSheriff or S.espInnocent then
                local box=Drawing.new("Square")
                box.Visible=false; box.Filled=false
                box.Color=S.espColorPlr; box.Thickness=1.5
                d.box=box
            end
            if S.espNames then
                local nm=Drawing.new("Text")
                nm.Text=plr.Name; nm.Color=T.white
                nm.Size=14; nm.Center=true; nm.Outline=true; nm.Visible=false
                d.nm=nm
            end
            if S.espDist then
                local dt=Drawing.new("Text")
                dt.Color=T.accentNeon; dt.Size=12; dt.Center=true
                dt.Outline=true; dt.Visible=false
                d.dt=dt
            end
            if S.targetESP then
                local tr=Drawing.new("Line")
                tr.Color=T.accent; tr.Thickness=1; tr.Visible=false
                d.tr=tr
            end
            espDrawings[plr.UserId]=d
        end
    end
end

-- world to screen helper
local function w2s(pos)
    local p,vis=cam:WorldToViewportPoint(pos)
    return Vector2.new(p.X,p.Y), vis, p.Z
end

RunService.RenderStepped:Connect(function()
    -- ESP render
    for uid,d in pairs(espDrawings) do
        local plr=Players:GetPlayerByUserId(uid)
        if plr and plr.Character then
            local root=plr.Character:FindFirstChild("HumanoidRootPart")
            local hum2=plr.Character:FindFirstChildOfClass("Humanoid")
            if root and hum2 then
                local sp,vis=w2s(root.Position)
                local color=getRoleColor(plr)
                if vis then
                    if d.box then
                        local top,_=w2s(root.Position+Vector3.new(0,3.2,0))
                        local bot,_=w2s(root.Position-Vector3.new(0,2.8,0))
                        local h3=math.abs(top.Y-bot.Y); local w3=h3*0.55
                        d.box.Size=Vector2.new(w3,h3)
                        d.box.Position=Vector2.new(sp.X-w3/2,math.min(top.Y,bot.Y))
                        d.box.Color=color; d.box.Visible=true
                    end
                    if d.nm then
                        d.nm.Position=Vector2.new(sp.X,sp.Y-70)
                        d.nm.Visible=true
                    end
                    if d.dt then
                        local hrp2=getHRP()
                        local dist=hrp2 and math.floor((hrp2.Position-root.Position).Magnitude) or 0
                        d.dt.Text=dist.."m | HP:"..math.floor(hum2.Health)
                        d.dt.Position=Vector2.new(sp.X,sp.Y+36)
                        d.dt.Visible=true
                    end
                    if d.tr then
                        d.tr.From=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y)
                        d.tr.To=sp; d.tr.Visible=true
                    end
                else
                    for _,v in pairs(d) do pcall(function() v.Visible=false end) end
                end
            end
        else
            cleanESP(uid)
        end
    end

    -- item/coin ESP
    if S.espItems or S.espCoins then
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                local n=obj.Name:lower()
                local isCoin=n:find("coin") or n:find("gold")
                local isItem=n:find("knife") or n:find("gun") or n:find("weapon") or n:find("revolver")
                if (S.espCoins and isCoin) or (S.espItems and isItem) then
                    local sp2,vis2=w2s(obj.Position)
                    if vis2 then
                        -- just draw a dot indicator (Drawing.new Text)
                        -- we reuse a shared drawing table for world objects
                        -- (creates per-frame; pooling out of scope here)
                    end
                end
            end
        end
    end

    -- Aimbot / Aim Kill
    if S.aimbot or S.aimKill then
        local hrp3=getHRP(); if not hrp3 then return end
        local best,bestD=nil,math.huge
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=lp and plr.Character then
                local r=plr.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d3=(hrp3.Position-r.Position).Magnitude
                    local sp3,vis3=w2s(r.Position)
                    if vis3 and d3<bestD then bestD=d3; best=plr end
                end
            end
        end
        if best and best.Character then
            if S.aimbot then
                local head=best.Character:FindFirstChild("Head")
                if head then cam.CFrame=CFrame.new(cam.CFrame.Position,head.Position) end
            end
            if S.aimKill and bestD<20 then
                local h5=best.Character:FindFirstChildOfClass("Humanoid")
                if h5 then h5.Health=0 end
            end
        end
    end
end)

-- ═══════════════════════════════════════
--  FARM ENGINE
-- ═══════════════════════════════════════
local farmConns={}

local function stopFarm(key)
    if farmConns[key] then farmConns[key]:Disconnect(); farmConns[key]=nil end
end

local coinTimerLbl, itemTimerLbl, totalTimerLbl
local coinCntLbl, itemCntLbl

local function startFarmCoins()
    stopFarm("coins")
    S.coinStart=tick(); S.farmStatus="RUNNING"
    farmConns["coins"]=RunService.Heartbeat:Connect(function()
        local dt=tick()-S.coinStart; S.coinStart=tick(); S.coinTime+=dt
        local hrp4=getHRP(); if not hrp4 then return end
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                local n=obj.Name:lower()
                if n:find("coin") or n:find("gold") or n:find("cash") then
                    if (hrp4.Position-obj.Position).Magnitude<24 then
                        S.coinCount+=1; obj.CFrame=hrp4.CFrame
                    end
                end
            end
        end
    end)
end

local function startFarmItems()
    stopFarm("items")
    S.itemStart=tick()
    farmConns["items"]=RunService.Heartbeat:Connect(function()
        local dt=tick()-S.itemStart; S.itemStart=tick(); S.itemTime+=dt
        local hrp5=getHRP(); if not hrp5 then return end
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Tool") then
                local n=obj.Name:lower()
                if n:find("knife") or n:find("gun") or n:find("revolver") or
                   n:find("item") or n:find("weapon") or n:find("drop") then
                    if (hrp5.Position-obj.Position).Magnitude<28 then
                        S.itemCount+=1; obj.CFrame=hrp5.CFrame
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════
--  HEARTBEAT — timers & stats
-- ═══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if coinTimerLbl then coinTimerLbl.Text=fmt(S.coinTime) end
    if itemTimerLbl then itemTimerLbl.Text=fmt(S.itemTime) end
    if totalTimerLbl then totalTimerLbl.Text=fmt(S.coinTime+S.itemTime) end
    if coinCntLbl then coinCntLbl.Text=tostring(S.coinCount) end
    if itemCntLbl then itemCntLbl.Text=tostring(S.itemCount) end
end)

-- ═══════════════════════════════════════
--  TAB BUILDERS
-- ═══════════════════════════════════════
local builders={}

-- ── PLAYER ──────────────────────────────
builders.PLAYER=function()
    clearScroll()
    mkSection("Movement","Controle de movimento")
    mkSlider("Walk Speed","Studs/s — padrão 16",10,500,S.walkSpeed,function(v)
        S.walkSpeed=v; if S.speedOn then local h=getHum(); if h then h.WalkSpeed=v end end
    end)
    mkToggle("Speed Enable","Ativar velocidade personalizada",S.speedOn,function(v)
        S.speedOn=v; local h=getHum(); if h then h.WalkSpeed=v and S.walkSpeed or 16 end
    end)
    mkSection("Jump","Configuração de salto")
    mkSlider("Jump Power","Força — padrão 50",50,500,S.jumpPower,function(v)
        S.jumpPower=v; if S.jumpOn then local h=getHum(); if h then h.JumpPower=v end end
    end)
    mkToggle("Jump Enable","Aplicar jump power",S.jumpOn,function(v)
        S.jumpOn=v; local h=getHum(); if h then h.JumpPower=v and S.jumpPower or 50 end
    end)
    mkToggle("Infinite Jump","Salto infinito no ar",S.infJump,function(v) S.infJump=v end)
    mkSection("Fly","Voo livre")
    mkToggle("Fly Mode","WASD + Space/Shift",S.flyOn,function(v)
        S.flyOn=v; if v then startFly() else stopFly() end
    end)
    mkSection("Noclip","Atravessar paredes")
    mkToggle("Noclip","Sem colisão",S.noclipOn,function(v)
        S.noclipOn=v; if v then startNoclip() else stopNoclip() end
    end)
end

-- ── ESP ─────────────────────────────────
builders.ESP=function()
    clearScroll()
    mkSection("Player ESP","Visualização de jogadores")
    mkToggle("Player ESP","Caixas em todos os jogadores",S.espPlayers,function(v)
        S.espPlayers=v; rebuildESP()
    end)
    mkToggle("Murderer ESP","Destaca assassinos",S.espMurderer,function(v)
        S.espMurderer=v; rebuildESP()
    end)
    mkToggle("Sheriff ESP","Destaca xerifes",S.espSheriff,function(v)
        S.espSheriff=v; rebuildESP()
    end)
    mkToggle("Innocent ESP","Destaca inocentes",S.espInnocent,function(v)
        S.espInnocent=v; rebuildESP()
    end)
    mkSection("Objects","Objetos do mapa")
    mkToggle("Item ESP","Facas e armas",S.espItems,function(v)
        S.espItems=v; rebuildESP()
    end)
    mkToggle("Coin ESP","Moedas no mapa",S.espCoins,function(v)
        S.espCoins=v; rebuildESP()
    end)
    mkSection("Display","Informações exibidas")
    mkToggle("Name ESP","Nome acima das caixas",S.espNames,function(v)
        S.espNames=v; rebuildESP()
    end)
    mkToggle("Distance ESP","Distância + HP em tempo real",S.espDist,function(v)
        S.espDist=v; rebuildESP()
    end)
    mkSection("Combat","Identificação e combate")
    mkToggle("Aim Kill","Eliminar alvo mais próximo (<20m)",S.aimKill,function(v)
        S.aimKill=v
    end)
    mkToggle("Aimbot","Câmera travada no alvo",S.aimbot,function(v)
        S.aimbot=v
    end)
    mkToggle("Target ESP","Tracer até o alvo",S.targetESP,function(v)
        S.targetESP=v; rebuildESP()
    end)
end

-- ── VISUAL ───────────────────────────────
builders.VISUAL=function()
    clearScroll()
    mkSection("Lighting","Iluminação")
    mkToggle("Fullbright","Remove escuridão",S.fullbright,function(v)
        S.fullbright=v
        if v then Lighting.Brightness=10; Lighting.ClockTime=14; Lighting.FogEnd=1e5
              Lighting.GlobalShadows=false
        else  Lighting.Brightness=S.brightness; Lighting.GlobalShadows=true end
    end)
    mkToggle("No Fog","Remove névoa",S.noFog,function(v)
        S.noFog=v; Lighting.FogEnd=v and 1e5 or 1000
    end)
    mkSlider("Brightness","Brilho do ambiente",0,10,S.brightness,function(v)
        S.brightness=v; if not S.fullbright then Lighting.Brightness=v end
    end)
    mkSection("Camera","Câmera")
    mkSlider("FOV","Field of View — padrão 70",50,120,S.fov,function(v)
        S.fov=v; cam.FieldOfView=v
    end)
    mkSection("Interface","Aparência da UI")
    mkSlider("Background Alpha","Transparência do fundo",10,100,
        math.floor(S.bgAlpha*100),function(v)
        S.bgAlpha=v/100; Win.BackgroundTransparency=1-S.bgAlpha
    end)
    mkSlider("Neon Intensity","Intensidade dos efeitos neon",0,100,60,function(v)
        TopLine.BackgroundTransparency=1-(v/100)
    end)
end

-- ── FARM ─────────────────────────────────
builders.FARM=function()
    clearScroll()
    mkSection("Auto Farm","Coleta automática")
    mkToggle("Farm Coins","Coletar moedas automaticamente",S.farmCoins,function(v)
        S.farmCoins=v
        if v then startFarmCoins() else stopFarm("coins"); S.farmStatus="STOPPED" end
    end)
    mkToggle("Farm Items","Coletar itens e armas",S.farmItems,function(v)
        S.farmItems=v
        if v then startFarmItems() else stopFarm("items") end
    end)
    mkSection("Timers","Cronômetros de sessão")
    local _,ctl=mkStat("COINS TIMER","00:00:00",T.accentNeon)
    coinTimerLbl=ctl
    local _,itl=mkStat("ITEMS TIMER","00:00:00",T.cyan)
    itemTimerLbl=itl
    local _,ttl=mkStat("TOTAL FARM TIME","00:00:00",T.accent)
    totalTimerLbl=ttl
    mkSection("Counters","Contadores")
    local _,ccl=mkStat("COINS COLETADAS","0",T.yellow)
    coinCntLbl=ccl
    local _,icl=mkStat("ITEMS COLETADOS","0",T.green)
    itemCntLbl=icl
    mkAction("Reset Contadores",T.accentDim,function()
        S.coinCount=0; S.itemCount=0
        S.coinTime=0;  S.itemTime=0
    end)
end

-- ── COLOR ────────────────────────────────
builders.COLOR=function()
    clearScroll()
    mkSection("Accent Color","Cor principal da interface")
    local colorMap={
        {"Vermelho","red"},{"Roxo","purple"},{"Azul","blue"},
        {"Verde","green"},{"Rosa","pink"},{"Branco","white"},{"Ciano","cyan"}
    }
    for _,pair in ipairs(colorMap) do
        local label,key=pair[1],pair[2]
        local ac=ACCENTS[key]
        local card=mkCard(50)
        card.BackgroundColor3=ac.main
        card.BackgroundTransparency=0.25
        newInst("TextLabel",{
            Size=UDim2.new(0.6,0,1,0),Position=UDim2.new(0,14,0,0),
            Text=label,TextColor3=T.white,TextSize=13,
            Font=Enum.Font.GothamBold,BackgroundTransparency=1,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=card
        })
        local sel=newInst("Frame",{
            Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-38,0.5,-10),
            BackgroundColor3=(S.accentKey==key) and T.white or Color3.fromRGB(50,50,70),
            ZIndex=12,Parent=card
        })
        corner(sel,10)
        local h=newInst("TextButton",{
            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="",ZIndex=13,Parent=card
        })
        h.MouseButton1Click:Connect(function()
            applyAccent(key)
            builders.COLOR()
        end)
    end
    mkSection("ESP Colors","Cores dos indicadores ESP")
    mkSection("Player","Cor dos jogadores neutros")
    mkAction("Branco",Color3.fromRGB(50,50,70),function()
        S.espColorPlr=T.white; rebuildESP()
    end)
    mkAction("Ciano",Color3.fromRGB(20,60,80),function()
        S.espColorPlr=T.cyan; rebuildESP()
    end)
end

-- ── CONFIG ───────────────────────────────
builders.CONFIG=function()
    clearScroll()
    mkSection("Save / Load","Configurações persistentes")
    mkAction("💾  Save Configuration",T.accentDim,function()
        pcall(function()
            if writefile then
                writefile("mm2_ult_config.json",HttpService:JSONEncode({
                    walkSpeed=S.walkSpeed,jumpPower=S.jumpPower,
                    fov=S.fov,bgAlpha=S.bgAlpha,accentKey=S.accentKey,
                    brightness=S.brightness
                }))
            end
        end)
    end)
    mkAction("📂  Load Configuration",Color3.fromRGB(20,20,40),function()
        pcall(function()
            if readfile and isfile and isfile("mm2_ult_config.json") then
                local d=HttpService:JSONDecode(readfile("mm2_ult_config.json"))
                for k,v in pairs(d) do if S[k]~=nil then S[k]=v end end
                applyAccent(S.accentKey)
            end
        end)
    end)
    mkAction("🔄  Reset to Default",Color3.fromRGB(60,20,20),function()
        S.walkSpeed=16; S.jumpPower=50; S.fov=70
        S.bgAlpha=0.75; S.brightness=1
        applyAccent("purple")
        builders.CONFIG()
    end)
    mkSection("Window","Controles da janela")
    mkAction("— Minimizar",Color3.fromRGB(20,20,40),function()
        S.open=false; Win.Visible=false; Shadow.Visible=false
    end)
    mkAction("✕ Fechar",Color3.fromRGB(60,16,24),function()
        S.open=false; Win.Visible=false; Shadow.Visible=false
    end)
    mkSection("Info","Sobre o script")
    mkSection("MM2 Ultimate v2.0","DEVELOPED BY LEONARDO")
    mkSection("Delta Executor","Lua 5.1 | Drawing API")
end

-- ═══════════════════════════════════════
--  TAB SWITCH
-- ═══════════════════════════════════════
local function switchTab(name)
    for _,t in ipairs(TABS) do
        local btn=tabBtns[t]; local ul=tabLines[t]
        if t==name then
            tween(btn,{TextColor3=T.textPri},0.15)
            tween(ul,{BackgroundTransparency=0},0.15)
        else
            tween(btn,{TextColor3=T.textDim},0.15)
            tween(ul,{BackgroundTransparency=1},0.15)
        end
    end
    S.tab=name
    if builders[name] then builders[name]() end
end

for _,name in ipairs(TABS) do
    tabBtns[name].MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

-- ═══════════════════════════════════════
--  WINDOW OPEN/CLOSE
-- ═══════════════════════════════════════
local function openMenu()
    S.open=true
    Shadow.Visible=true; Win.Visible=true
    Win.BackgroundTransparency=1
    tween(Win,{BackgroundTransparency=1-S.bgAlpha},0.2)
    switchTab(S.tab)
end
local function closeMenu()
    S.open=false
    tween(Win,{BackgroundTransparency=1},0.15)
    task.delay(0.15,function()
        Win.Visible=false; Shadow.Visible=false
    end)
end

CloseBtn.MouseButton1Click:Connect(closeMenu)
MinBtn.MouseButton1Click:Connect(closeMenu)

local fabLastClick=0
FABBtn.MouseButton1Click:Connect(function()
    local now=tick()
    if now-fabLastClick<0.25 then return end
    fabLastClick=now
    if fabMoved then fabMoved=false; return end
    if S.open then closeMenu() else openMenu() end
end)

-- ═══════════════════════════════════════
--  STARTUP
-- ═══════════════════════════════════════
applyAccent("purple")
switchTab("PLAYER")

print("[MM2 Ultimate] Carregado. Toque no botão UK1N.")
print("[MM2 Ultimate] DEVELOPED BY LEONARDO")
