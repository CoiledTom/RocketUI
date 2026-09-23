--[[
    RocketUI Full Demo
    CoiledTom
    Roblox / Delta
    Visual-first build
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local CONFIG = {
    Name = "RocketUI",
    Version = "1.0",

    Background = Color3.fromRGB(8, 9, 11),
    Window = Color3.fromRGB(14, 15, 18),
    Sidebar = Color3.fromRGB(12, 13, 16),
    Card = Color3.fromRGB(20, 21, 25),
    CardHover = Color3.fromRGB(27, 28, 33),

    Border = Color3.fromRGB(48, 49, 56),
    BorderSoft = Color3.fromRGB(35, 36, 42),

    Text = Color3.fromRGB(240, 240, 244),
    SubText = Color3.fromRGB(145, 147, 155),
    Muted = Color3.fromRGB(92, 94, 102),

    Orange = Color3.fromRGB(255, 118, 24),
    Orange2 = Color3.fromRGB(255, 150, 45),

    Purple = Color3.fromRGB(143, 92, 255),
    Red = Color3.fromRGB(235, 70, 75),
    Green = Color3.fromRGB(55, 210, 110),
    Blue = Color3.fromRGB(70, 145, 255),
    Pink = Color3.fromRGB(230, 70, 180),

    SidebarOpen = 235,
    SidebarClosed = 68,
}

--==================================================
-- CLEAN OLD GUI
--==================================================

local GUI_NAME = "RocketUI_Full"

local old = nil

pcall(function()
    local hui = gethui
    if hui then
        old = hui():FindFirstChild(GUI_NAME)
    end
end)

if not old then
    pcall(function()
        old = Player.PlayerGui:FindFirstChild(GUI_NAME)
    end)
end

if old then
    old:Destroy()
end

--==================================================
-- GUI ROOT
--==================================================

local Parent

pcall(function()
    if gethui then
        Parent = gethui()
    end
end)

if not Parent then
    Parent = Player:WaitForChild("PlayerGui")
end

local Screen = Instance.new("ScreenGui")
Screen.Name = GUI_NAME
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = Parent

--==================================================
-- HELPERS
--==================================================

local function New(class, props, parent)
    local obj = Instance.new(class)

    for key, value in pairs(props or {}) do
        pcall(function()
            obj[key] = value
        end)
    end

    obj.Parent = parent
    return obj
end

local function Corner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or CONFIG.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, parent)
end

local function Padding(parent, left, right, top, bottom)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, parent)
end

local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function FastTween(obj, props)
    return Tween(
        obj,
        TweenInfo.new(
            0.18,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        props
    )
end

local function MakeText(parent, text, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or CONFIG.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end

--==================================================
-- ICON SYSTEM
--==================================================

local Icons = {}

local ICON_URL =
    "https://raw." ..
    "githubusercontent.com/CoiledTom/RocketUI/refs/heads/main/Icons.lua"

pcall(function()
    local source = game:HttpGet(ICON_URL)
    local fn = loadstring(source)

    if fn then
        local ok, result = pcall(fn)

        if ok and type(result) == "table" then
            Icons = result
        end
    end
end)

local FallbackIcons = {
    Home = "⌂",
    Compass = "◇",
    Message = "□",
    Bell = "♧",
    Chart = "⌁",
    Plus = "+",
    Bookmark = "▢",
    User = "○",
    Settings = "⚙",
    Search = "⌕",
    ChevronLeft = "‹",
    ChevronRight = "›",
    ChevronDown = "⌄",
    Check = "✓",
    X = "×",
    Flame = "♨",
    Folder = "□",
    Calendar = "□",
    Sliders = "☷",
    Info = "i",
    Help = "?",
    Shield = "◇",
    Key = "◆",
    Lock = "▣",
    Trash = "×",
    Eye = "◉",
    Star = "★",
    Zap = "ϟ",
    Download = "↓",
    Upload = "↑",
    Copy = "□",
}

local function GetIcon(name)
    local icon = Icons[name]

    if icon == nil then
        return FallbackIcons[name] or "•"
    end

    return icon
end

local function CreateIcon(parent, name, size, color)
    local value = GetIcon(name)

    if type(value) == "number" then
        value = "rbxassetid://" .. tostring(value)
    end

    if type(value) == "string" and (
        string.find(value, "rbxassetid://") or
        string.find(value, "http")
    ) then

        local image = New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = value,
            ImageColor3 = color or CONFIG.SubText,
            Size = UDim2.fromOffset(size or 20, size or 20),
            ScaleType = Enum.ScaleType.Fit
        }, parent)

        return image
    end

    local label = MakeText(
        parent,
        tostring(value),
        size or 20,
        color or CONFIG.SubText,
        Enum.Font.GothamMedium
    )

    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center

    return label
end

--==================================================
-- WINDOW
--==================================================

local Window = New("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 940, 0, 590),

    BackgroundColor3 = CONFIG.Window,
    BackgroundTransparency = 0.08,

    ClipsDescendants = true,
}, Screen)

Corner(Window, 15)
Stroke(Window, CONFIG.Border, 1, 0.25)

--==================================================
-- TOP BAR
--==================================================

local TopBar = New("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = CONFIG.Window,
    BackgroundTransparency = 0.05,
}, Window)

local TopLine = New("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = CONFIG.BorderSoft,
    BorderSizePixel = 0,
}, TopBar)

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Window.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    Window.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

--==================================================
-- BRAND
--==================================================

local Brand = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 0),
    Size = UDim2.fromOffset(220, 58)
}, TopBar)

local BrandMark = New("Frame", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(0, 0, 0.5, -16),
    BackgroundColor3 = CONFIG.Orange,
    BackgroundTransparency = 0.08
}, Brand)

Corner(BrandMark, 9)

MakeText(
    BrandMark,
    "R",
    17,
    Color3.new(1,1,1),
    Enum.Font.GothamBold
).Size = UDim2.fromScale(1,1)

local BrandText = MakeText(
    Brand,
    "RocketUI",
    17,
    CONFIG.Text,
    Enum.Font.GothamBold
)

BrandText.Position = UDim2.fromOffset(43, 9)
BrandText.Size = UDim2.fromOffset(150, 22)

local VersionText = MakeText(
    Brand,
    "CoiledTom • 1.0",
    10,
    CONFIG.Muted,
    Enum.Font.Gotham
)

VersionText.Position = UDim2.fromOffset(43, 30)
VersionText.Size = UDim2.fromOffset(150, 18)

--==================================================
-- WINDOW CONTROLS
--==================================================

local Controls = New("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 0),
    Size = UDim2.fromOffset(115, 58)
}, TopBar)

local function WindowButton(symbol, color)
    local b = New("TextButton", {
        BackgroundColor3 = CONFIG.Card,
        BackgroundTransparency = 0.2,
        Text = symbol,
        TextColor3 = color or CONFIG.SubText,
        TextSize = 17,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(32, 32),
    }, Controls)

    Corner(b, 8)

    b.MouseEnter:Connect(function()
        FastTween(b, {
            BackgroundColor3 = CONFIG.CardHover,
            TextColor3 = CONFIG.Text
        })
    end)

    b.MouseLeave:Connect(function()
        FastTween(b, {
            BackgroundColor3 = CONFIG.Card,
            TextColor3 = color or CONFIG.SubText
        })
    end)

    return b
end

local MinimizeButton = WindowButton("−")
MinimizeButton.Position = UDim2.fromOffset(0, 13)

local CollapseButton = WindowButton("‹")
CollapseButton.Position = UDim2.fromOffset(39, 13)

local CloseButton = WindowButton("×", CONFIG.Red)
CloseButton.Position = UDim2.fromOffset(78, 13)

CloseButton.MouseButton1Click:Connect(function()
    Screen:Destroy()
end)

--==================================================
-- BODY
--==================================================

local Body = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 1, -58),
}, Window)

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = New("Frame", {
    BackgroundColor3 = CONFIG.Sidebar,
    BackgroundTransparency = 0.08,
    Size = UDim2.new(0, CONFIG.SidebarOpen, 1, 0),
    ClipsDescendants = true
}, Body)

local SideStroke = Stroke(Sidebar, CONFIG.BorderSoft, 1, 0.3)

local SidePadding = Padding(Sidebar, 12, 12, 15, 12)

local SideHeader = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 35)
}, Sidebar)

local SideTitle = MakeText(
    SideHeader,
    "MENU",
    11,
    CONFIG.Muted,
    Enum.Font.GothamMedium
)

SideTitle.Size = UDim2.new(1, -45, 1, 0)

local SideCollapse = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, 0, 0.5, 0),
    Size = UDim2.fromOffset(30, 30),

    BackgroundTransparency = 1,
    Text = "‹",
    TextColor3 = CONFIG.SubText,
    TextSize = 23,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = false
}, SideHeader)

--==================================================
-- SIDEBAR SCROLL
--==================================================

local SideScroll = New("ScrollingFrame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 45),
    Size = UDim2.new(1, 0, 1, -45),

    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,

    ScrollBarThickness = 2,
    ScrollBarImageColor3 = CONFIG.Border,
    BorderSizePixel = 0,
}, Sidebar)

local SideLayout = New("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, SideScroll)

--==================================================
-- PAGE SYSTEM
--==================================================

local Pages = {}
local CurrentPage = nil

local function CreatePage(name)
    local page = New("ScrollingFrame", {
        Name = name,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, CONFIG.SidebarOpen, 0, 0),
        Size = UDim2.new(1, -CONFIG.SidebarOpen, 1, 0),

        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CONFIG.Border,

        BorderSizePixel = 0,

        Visible = false,
    }, Body)

    Padding(page, 25, 25, 22, 25)

    Pages[name] = page

    return page
end

local HomePage = CreatePage("Home")
local ComponentsPage = CreatePage("Components")
local SettingsPage = CreatePage("Settings")
local AboutPage = CreatePage("About")

--==================================================
-- SIDEBAR ITEM
--==================================================

local SidebarItems = {}

local function SidebarButton(text, icon, pageName, accent)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42)
    }, SideScroll)

    local button = New("TextButton", {
        BackgroundColor3 = CONFIG.Card,
        BackgroundTransparency = 1,

        Size = UDim2.new(1, 0, 1, 0),

        Text = "",
        AutoButtonColor = false,
    }, holder)

    Corner(button, 9)

    local iconFrame = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.fromOffset(30, 30)
    }, button)

    local iconObject = CreateIcon(
        iconFrame,
        icon,
        19,
        CONFIG.SubText
    )

    iconObject.AnchorPoint = Vector2.new(0.5, 0.5)
    iconObject.Position = UDim2.fromScale(0.5, 0.5)

    local label = MakeText(
        button,
        text,
        13,
        CONFIG.SubText,
        Enum.Font.GothamMedium
    )

    label.Position = UDim2.fromOffset(49, 0)
    label.Size = UDim2.new(1, -58, 1, 0)

    local activeLine = New("Frame", {
        BackgroundColor3 = accent or CONFIG.Orange,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 7),
        Size = UDim2.fromOffset(3, 28)
    }, button)

    Corner(activeLine, 3)

    SidebarItems[pageName] = {
        Button = button,
        Label = label,
        Icon = iconObject,
        Line = activeLine,
    }

    button.MouseEnter:Connect(function()
        if CurrentPage ~= pageName then
            FastTween(button, {
                BackgroundColor3 = CONFIG.CardHover,
                BackgroundTransparency = 0.3
            })
        end
    end)

    button.MouseLeave:Connect(function()
        if CurrentPage ~= pageName then
            FastTween(button, {
                BackgroundTransparency = 1
            })
        end
    end)

    button.MouseButton1Click:Connect(function()
        for page, data in pairs(SidebarItems) do
            local active = page == pageName

            FastTween(data.Button, {
                BackgroundTransparency = active and 0 or 1,
                BackgroundColor3 = active and CONFIG.Card or CONFIG.CardHover
            })

            FastTween(data.Label, {
                TextColor3 = active and CONFIG.Text or CONFIG.SubText
            })

            FastTween(data.Icon, {
                ImageColor3 = active and (accent or CONFIG.Orange) or CONFIG.SubText
            })

            FastTween(data.Line, {
                BackgroundTransparency = active and 0 or 1
            })

            if Pages[page] then
                Pages[page].Visible = active
            end
        end

        CurrentPage = pageName
    end)

    return holder
end

SidebarButton("Home", "Home", "Home", CONFIG.Orange)
SidebarButton("Components", "Sliders", "Components", CONFIG.Purple)
SidebarButton("Settings", "Settings", "Settings", CONFIG.Blue)
SidebarButton("About", "Info", "About", CONFIG.Pink)

--==================================================
-- SIDEBAR SEPARATOR
--==================================================

New("Frame", {
    BackgroundColor3 = CONFIG.BorderSoft,
    BackgroundTransparency = 0.25,
    Size = UDim2.new(1, 0, 0, 1),
}, SideScroll)

local OtherLabel = MakeText(
    SideScroll,
    "OTHER",
    10,
    CONFIG.Muted,
    Enum.Font.GothamMedium
)

OtherLabel.Size = UDim2.new(1, 0, 0, 28)

SidebarButton("Help", "Help", "About", CONFIG.SubText)

--==================================================
-- SIDEBAR FOOTER
--==================================================

local Footer = New("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 12, 1, -12),
    Size = UDim2.new(1, -24, 0, 52),

    BackgroundColor3 = CONFIG.Card,
    BackgroundTransparency = 0.25
}, Sidebar)

Corner(Footer, 10)
Stroke(Footer, CONFIG.BorderSoft, 1, 0.35)

local Fire = CreateIcon(
    Footer,
    "Flame",
    20,
    CONFIG.Orange
)

Fire.Position = UDim2.fromOffset(12, 16)

local FooterText = MakeText(
    Footer,
    "RocketUI",
    12,
    CONFIG.Text,
    Enum.Font.GothamMedium
)

FooterText.Position = UDim2.fromOffset(40, 8)
FooterText.Size = UDim2.new(1, -45, 18)

local FooterSub = MakeText(
    Footer,
    "CoiledTom",
    9,
    CONFIG.Muted
)

FooterSub.Position = UDim2.fromOffset(40, 25)
FooterSub.Size = UDim2.new(1, -45, 16)

--==================================================
-- COMPONENT HELPERS
--==================================================

local function SectionTitle(parent, title, subtitle)
    local frame = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, subtitle and 55 or 34)
    }, parent)

    local t = MakeText(
        frame,
        title,
        21,
        CONFIG.Text,
        Enum.Font.GothamBold
    )

    t.Size = UDim2.new(1, 0, 0, 29)

    if subtitle then
        local s = MakeText(
            frame,
            subtitle,
            11,
            CONFIG.SubText
        )

        s.Position = UDim2.fromOffset(0, 28)
        s.Size = UDim2.new(1, 0, 0, 22)
    end

    return frame
end

local function Card(parent, height)
    local card = New("Frame", {
        BackgroundColor3 = CONFIG.Card,
        BackgroundTransparency = 0.18,
        Size = UDim2.new(1, 0, 0, height or 100)
    }, parent)

    Corner(card, 12)
    Stroke(card, CONFIG.BorderSoft, 1, 0.35)

    return card
end

local function Badge(parent, text, color)
    local b = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 24),

        BackgroundColor3 = color,
        BackgroundTransparency = 0.82,

        Text = "  " .. text .. "  ",
        TextColor3 = color,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
    }, parent)

    Corner(b, 7)

    return b
end

local function StandardButton(parent, text, icon, color)
    local b = New("TextButton", {
        BackgroundColor3 = color or CONFIG.Orange,
        BackgroundTransparency = 0.08,

        Size = UDim2.new(1, 0, 0, 40),

        Text = "",
        AutoButtonColor = false
    }, parent)

    Corner(b, 9)

    if icon then
        local ic = CreateIcon(
            b,
            icon,
            17,
            Color3.new(1,1,1)
        )

        ic.Position = UDim2.fromOffset(12, 11)
    end

    local txt = MakeText(
        b,
        text,
        12,
        Color3.new(1,1,1),
        Enum.Font.GothamMedium
    )

    txt.Size = UDim2.new(1, -20, 1, 0)
    txt.Position = UDim2.fromOffset(icon and 38 or 10, 0)

    b.MouseEnter:Connect(function()
        FastTween(b, {
            BackgroundTransparency = 0
        })
    end)

    b.MouseLeave:Connect(function()
        FastTween(b, {
            BackgroundTransparency = 0.08
        })
    end)

    return b
end

local function GhostButton(parent, text)
    local b = New("TextButton", {
        BackgroundColor3 = CONFIG.CardHover,
        BackgroundTransparency = 0.35,

        Size = UDim2.new(1, 0, 0, 40),

        Text = text,
        TextColor3 = CONFIG.Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,

        AutoButtonColor = false
    }, parent)

    Corner(b, 9)
    Stroke(b, CONFIG.Border, 1, 0.3)

    return b
end

local function Toggle(parent, title, default, callback)
    local row = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52)
    }, parent)

    local text = MakeText(
        row,
        title,
        12,
        CONFIG.Text,
        Enum.Font.GothamMedium
    )

    text.Size = UDim2.new(1, -70, 1, 0)

    local switch = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),

        Size = UDim2.fromOffset(44, 24),

        BackgroundColor3 = default and CONFIG.Orange or CONFIG.Border,
        Text = "",
        AutoButtonColor = false
    }, row)

    Corner(switch, 20)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(18, 18),

        Position = default
            and UDim2.new(1, -21, 0.5, -9)
            or UDim2.new(0, 3, 0.5, -9),

        BackgroundColor3 = Color3.new(1,1,1)
    }, switch)

    Corner(knob, 20)

    local state = default

    switch.MouseButton1Click:Connect(function()
        state = not state

        FastTween(switch, {
            BackgroundColor3 = state and CONFIG.Orange or CONFIG.Border
        })

        FastTween(knob, {
            Position = state
                and UDim2.new(1, -21, 0.5, -9)
                or UDim2.new(0, 3, 0.5, -9)
        })

        if callback then
            callback(state)
        end
    end)

    return row
end

local function Slider(parent, title, min, max, default, callback)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 65)
    }, parent)

    local label = MakeText(
        holder,
        title,
        12,
        CONFIG.Text,
        Enum.Font.GothamMedium
    )

    label.Size = UDim2.new(1, -50, 0, 25)

    local valueLabel = MakeText(
        holder,
        tostring(default),
        11,
        CONFIG.Orange,
        Enum.Font.GothamMedium
    )

    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, 0, 0, 0)
    valueLabel.Size = UDim2.fromOffset(45, 25)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bar = New("Frame", {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = CONFIG.Border
    }, holder)

    Corner(bar, 5)

    local fill = New("Frame", {
        Size = UDim2.new(
            (default - min) / (max - min),
            0,
            1,
            0
        ),
        BackgroundColor3 = CONFIG.Orange
    }, bar)

    Corner(fill, 5)

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(
            (default - min) / (max - min),
            0,
            0.5,
            0
        ),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.new(1,1,1)
    }, bar)

    Corner(knob, 20)

    local draggingSlider = false

    local function SetValue(x)
        local percentage = math.clamp(
            (x - bar.AbsolutePosition.X) /
            bar.AbsoluteSize.X,
            0,
            1
        )

        local value = min + (max - min) * percentage
        value = math.floor(value + 0.5)

        fill.Size = UDim2.new(percentage, 0, 1, 0)
        knob.Position = UDim2.new(percentage, 0, 0.5, 0)
        valueLabel.Text = tostring(value)

        if callback then
            callback(value)
        end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingSlider = true
            SetValue(input.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if draggingSlider and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            SetValue(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)

    return holder
end

local function Dropdown(parent, title, options, default, callback)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58)
    }, parent)

    local label = MakeText(
        holder,
        title,
        11,
        CONFIG.SubText
    )

    label.Size = UDim2.new(1, 0, 0, 20)

    local button = New("TextButton", {
        Position = UDim2.fromOffset(0, 23),
        Size = UDim2.new(1, 0, 0, 35),

        BackgroundColor3 = CONFIG.CardHover,
        BackgroundTransparency = 0.2,

        Text = tostring(default),
        TextColor3 = CONFIG.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,

        AutoButtonColor = false
    }, holder)

    Padding(button, 11, 10, 0, 0)
    Corner(button, 8)
    Stroke(button, CONFIG.Border, 1, 0.4)

    local arrow = MakeText(
        button,
        "⌄",
        16,
        CONFIG.SubText
    )

    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -10, 0.5, 0)
    arrow.Size = UDim2.fromOffset(20, 20)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local list = New("Frame", {
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, #options * 32),

        BackgroundColor3 = CONFIG.Card,
        Visible = false,

        ZIndex = 20
    }, button)

    Corner(list, 8)
    Stroke(list, CONFIG.Border, 1, 0.2)

    local layout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder
    }, list)

    for _, option in ipairs(options) do
        local optionButton = New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),

            Text = "  " .. tostring(option),
            TextColor3 = CONFIG.SubText,
            TextSize = 11,
            Font = Enum.Font.Gotham,

            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,

            ZIndex = 21
        }, list)

        optionButton.MouseButton1Click:Connect(function()
            button.Text = tostring(option)
            list.Visible = false

            if callback then
                callback(option)
            end
        end)
    end

    button.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
    end)

    return holder
end

local function TextBox(parent, title, placeholder)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 62)
    }, parent)

    local label = MakeText(
        holder,
        title,
        11,
        CONFIG.SubText
    )

    label.Size = UDim2.new(1, 0, 0, 20)

    local box = New("TextBox", {
        Position = UDim2.fromOffset(0, 23),
        Size = UDim2.new(1, 0, 0, 36),

        BackgroundColor3 = CONFIG.CardHover,
        BackgroundTransparency = 0.2,

        Text = "",
        PlaceholderText = placeholder or "Digite aqui...",
        PlaceholderColor3 = CONFIG.Muted,

        TextColor3 = CONFIG.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,

        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    Padding(box, 11, 10, 0, 0)
    Corner(box, 8)
    Stroke(box, CONFIG.Border, 1, 0.35)

    return holder, box
end

--==================================================
-- HOME PAGE
--==================================================

SectionTitle(
    HomePage,
    "RocketUI",
    "Interface completa inspirada nas referências visuais."
)

local Hero = Card(HomePage, 145)
Hero.LayoutOrder = 2

local HeroTitle = MakeText(
    Hero,
    "Welcome to RocketUI",
    18,
    CONFIG.Text,
    Enum.Font.GothamBold
)

HeroTitle.Position = UDim2.fromOffset(18, 15)
HeroTitle.Size = UDim2.new(1, -36, 25)

local HeroDescription = MakeText(
    Hero,
    "Uma UI escura, compacta, transparente e feita para funcionar muito bem em mobile.",
    11,
    CONFIG.SubText
)

HeroDescription.Position = UDim2.fromOffset(18, 42)
HeroDescription.Size = UDim2.new(1, -36, 38)
HeroDescription.TextWrapped = true

local badge1 = Badge(Hero, "ROCKET", CONFIG.Orange)
badge1.Position = UDim2.fromOffset(18, 94)

local badge2 = Badge(Hero, "MOBILE", CONFIG.Purple)
badge2.Position = UDim2.fromOffset(92, 94)

local badge3 = Badge(Hero, "DARK", CONFIG.Blue)
badge3.Position = UDim2.fromOffset(173, 94)

local HeroButton = StandardButton(
    Hero,
    "Explore Components",
    "Sliders",
    CONFIG.Orange
)

HeroButton.Size = UDim2.fromOffset(170, 34)
HeroButton.Position = UDim2.new(1, -188, 1, -48)

HeroButton.MouseButton1Click:Connect(function()
    SidebarItems.Components.Button:Activate()
end)

--==================================================
-- STAT CARDS
--==================================================

local Stats = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 100)
}, HomePage)

local StatsLayout = New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 10)
}, Stats)

local function StatCard(title, value, color)
    local c = New("Frame", {
        BackgroundColor3 = CONFIG.Card,
        BackgroundTransparency = 0.18,
        Size = UDim2.new(0.333, -7, 1, 0)
    }, Stats)

    Corner(c, 11)
    Stroke(c, CONFIG.BorderSoft, 1, 0.35)

    local dot = New("Frame", {
        BackgroundColor3 = color,
        Position = UDim2.fromOffset(15, 18),
        Size = UDim2.fromOffset(7, 7)
    }, c)

    Corner(dot, 10)

    local val = MakeText(
        c,
        value,
        20,
        CONFIG.Text,
        Enum.Font.GothamBold
    )

    val.Position = UDim2.fromOffset(15, 30)
    val.Size = UDim2.new(1, -30, 30)

    local txt = MakeText(
        c,
        title,
        10,
        CONFIG.Muted
    )

    txt.Position = UDim2.fromOffset(15, 63)
    txt.Size = UDim2.new(1, -30, 20)

    return c
end

StatCard("Components", "28", CONFIG.Orange)
StatCard("Themes", "06", CONFIG.Purple)
StatCard("Status", "ONLINE", CONFIG.Green)

--==================================================
-- ACTIVITY CARD
--==================================================

local Activity = Card(HomePage, 165)

local ActivityTitle = MakeText(
    Activity,
    "Activity",
    14,
    CONFIG.Text,
    Enum.Font.GothamBold
)

ActivityTitle.Position = UDim2.fromOffset(18, 13)
ActivityTitle.Size = UDim2.new(1, -36, 25)

local ActivitySub = MakeText(
    Activity,
    "Current RocketUI system status",
    10,
    CONFIG.Muted
)

ActivitySub.Position = UDim2.fromOffset(18, 37)
ActivitySub.Size = UDim2.new(1, -36, 20)

local function ActivityRow(parent, y, text, color)
    local dot = New("Frame", {
        BackgroundColor3 = color,
        Position = UDim2.fromOffset(19, y + 5),
        Size = UDim2.fromOffset(7, 7)
    }, parent)

    Corner(dot, 10)

    local t = MakeText(
        parent,
        text,
        11,
        CONFIG.SubText
    )

    t.Position = UDim2.fromOffset(35, y)
    t.Size = UDim2.new(1, -50, 20)
end

ActivityRow(Activity, 68, "Interface loaded successfully", CONFIG.Green)
ActivityRow(Activity, 94, "Icon system connected", CONFIG.Purple)
ActivityRow(Activity, 120, "Mobile layout active", CONFIG.Orange)

--==================================================
-- COMPONENTS PAGE
--==================================================

SectionTitle(
    ComponentsPage,
    "Components",
    "Todos os principais controles visuais da RocketUI."
)

local ComponentCard = Card(ComponentsPage, 690)

Padding(ComponentCard, 18, 18, 15, 15)

local ComponentLayout = New("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, ComponentCard)

local ComponentHeading = MakeText(
    ComponentCard,
    "Controls",
    14,
    CONFIG.Text,
    Enum.Font.GothamBold
)

ComponentHeading.Size = UDim2.new(1, 0, 0, 25)

local ButtonRow = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 42)
}, ComponentCard)

local Primary = StandardButton(
    ButtonRow,
    "Primary Button",
    "Zap",
    CONFIG.Orange
)

Primary.Size = UDim2.new(0.49, -4, 1, 0)

local Secondary = GhostButton(
    ButtonRow,
    "Secondary Button"
)

Secondary.Position = UDim2.new(0.51, 0, 0, 0)
Secondary.Size = UDim2.new(0.49, -4, 1, 0)

Toggle(
    ComponentCard,
    "Enable Rocket Mode",
    true
)

Toggle(
    ComponentCard,
    "Animations",
    true
)

Toggle(
    ComponentCard,
    "Transparent Background",
    true
)

Slider(
    ComponentCard,
    "UI Scale",
    50,
    150,
    100
)

Slider(
    ComponentCard,
    "Transparency",
    0,
    100,
    15
)

Dropdown(
    ComponentCard,
    "Theme",
    {
        "Obsidian",
        "Midnight",
        "Violet",
        "Orange",
        "Crimson"
    },
    "Obsidian"
)

Dropdown(
    ComponentCard,
    "Icon Source",
    {
        "RocketUI",
        "Lucide",
        "Solar",
        "Geist"
    },
    "RocketUI"
)

TextBox(
    ComponentCard,
    "Search",
    "Digite algo..."
)

TextBox(
    ComponentCard,
    "Key",
    "XXXX-XXXX-XXXX"
)

--==================================================
-- SETTINGS PAGE
--==================================================

SectionTitle(
    SettingsPage,
    "Settings",
    "Personalize a aparência e o comportamento da interface."
)

local SettingsCard = Card(SettingsPage, 430)
Padding(SettingsCard, 18, 18, 15, 15)

local SettingsLayout = New("UIListLayout", {
    Padding = UDim.new(0, 5)
}, SettingsCard)

local AppearanceTitle = MakeText(
    SettingsCard,
    "Appearance",
    14,
    CONFIG.Text,
    Enum.Font.GothamBold
)

AppearanceTitle.Size = UDim2.new(1, 0, 0, 30)

Toggle(SettingsCard, "Glass / Transparent UI", true)
Toggle(SettingsCard, "Soft Glow", true)
Toggle(SettingsCard, "Rounded Corners", true)
Toggle(SettingsCard, "Compact Mode", false)

Slider(
    SettingsCard,
    "Window Opacity",
    0,
    100,
    92
)

Dropdown(
    SettingsCard,
    "Accent Color",
    {
        "Orange",
        "Purple",
        "Red",
        "Blue",
        "Green"
    },
    "Orange"
)

local Reset = GhostButton(
    SettingsCard,
    "Reset Settings"
)

--==================================================
-- ABOUT PAGE
--==================================================

SectionTitle(
    AboutPage,
    "About RocketUI",
    "Interface library by CoiledTom."
)

local AboutCard = Card(AboutPage, 280)
Padding(AboutCard, 20, 20, 20, 20)

local AboutTitle = MakeText(
    AboutCard,
    "RocketUI",
    24,
    CONFIG.Text,
    Enum.Font.GothamBold
)

AboutTitle.Size = UDim2.new(1, 0, 35)

local AboutDescription = MakeText(
    AboutCard,
    "A visual-first Roblox UI system designed around compact layouts, dark surfaces, transparent panels and real iconography.",
    11,
    CONFIG.SubText
)

AboutDescription.Position = UDim2.fromOffset(0, 45)
AboutDescription.Size = UDim2.new(1, 0, 55)
AboutDescription.TextWrapped = true

local AboutVersion = Badge(
    AboutCard,
    "VERSION 1.0",
    CONFIG.Orange
)

AboutVersion.Position = UDim2.fromOffset(0, 120)

local AboutAuthor = MakeText(
    AboutCard,
    "Created by CoiledTom",
    11,
    CONFIG.Text,
    Enum.Font.GothamMedium
)

AboutAuthor.Position = UDim2.fromOffset(0, 160)
AboutAuthor.Size = UDim2.new(1, 0, 25)

local AboutStatus = MakeText(
    AboutCard,
    "● System ready",
    11,
    CONFIG.Green,
    Enum.Font.GothamMedium
)

AboutStatus.Position = UDim2.fromOffset(0, 195)
AboutStatus.Size = UDim2.new(1, 0, 25)

--==================================================
-- NOTIFICATION SYSTEM
--==================================================

local NotificationHolder = New("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.fromOffset(290, 300),

    BackgroundTransparency = 1
}, Screen)

local NotificationLayout = New("UIListLayout", {
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8)
}, NotificationHolder)

local function Notify(title, message, accent)
    local n = New("Frame", {
        BackgroundColor3 = CONFIG.Card,
        BackgroundTransparency = 0.04,
        Size = UDim2.new(1, 0, 0, 72)
    }, NotificationHolder)

    Corner(n, 11)
    Stroke(n, accent or CONFIG.Orange, 1, 0.25)

    local bar = New("Frame", {
        BackgroundColor3 = accent or CONFIG.Orange,
        Size = UDim2.fromOffset(3, 46),
        Position = UDim2.fromOffset(8, 13)
    }, n)

    Corner(bar, 3)

    local t = MakeText(
        n,
        title,
        12,
        CONFIG.Text,
        Enum.Font.GothamBold
    )

    t.Position = UDim2.fromOffset(22, 12)
    t.Size = UDim2.new(1, -32, 20)

    local m = MakeText(
        n,
        message,
        10,
        CONFIG.SubText
    )

    m.Position = UDim2.fromOffset(22, 34)
    m.Size = UDim2.new(1, -32, 27)
    m.TextWrapped = true

    task.delay(4, function()
        if n then
            FastTween(n, {
                BackgroundTransparency = 1
            })

            task.wait(0.2)

            if n then
                n:Destroy()
            end
        end
    end)
end

--==================================================
-- SIDEBAR COLLAPSE
--==================================================

local sidebarOpen = true

local function SetSidebar(state)
    sidebarOpen = state

    local targetWidth = state
        and CONFIG.SidebarOpen
        or CONFIG.SidebarClosed

    FastTween(
        Sidebar,
        {
            Size = UDim2.new(0, targetWidth, 1, 0)
        }
    )

    for _, page in pairs(Pages) do
        FastTween(
            page,
            {
                Position = UDim2.new(0, targetWidth, 0, 0),
                Size = UDim2.new(1, -targetWidth, 1, 0)
            }
        )
    end

    FastTween(
        SideCollapse,
        {
            Rotation = state and 0 or 180
        }
    )

    for _, data in pairs(SidebarItems) do
        FastTween(
            data.Label,
            {
                TextTransparency = state and 0 or 1
            }
        )
    end

    FastTween(
        Footer,
        {
            BackgroundTransparency = state and 0.25 or 1
        }
    )
end

SideCollapse.MouseButton1Click:Connect(function()
    SetSidebar(not sidebarOpen)
end)

CollapseButton.MouseButton1Click:Connect(function()
    SetSidebar(not sidebarOpen)
end)

--==================================================
-- MINIMIZE
--==================================================

local minimized = false

MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized

    if minimized then
        FastTween(
            Body,
            {
                Size = UDim2.new(1, 0, 0, 0)
            }
        )

        FastTween(
            Window,
            {
                Size = UDim2.new(0, 940, 0, 58)
            }
        )
    else
        FastTween(
            Window,
            {
                Size = UDim2.new(0, 940, 0, 590)
            }
        )

        task.wait(0.1)

        FastTween(
            Body,
            {
                Size = UDim2.new(1, 0, 1, -58)
            }
        )
    end
end)

--==================================================
-- INITIAL PAGE
--==================================================

CurrentPage = "Home"

for pageName, data in pairs(SidebarItems) do
    local active = pageName == "Home"

    data.Button.BackgroundTransparency = active and 0 or 1
    data.Label.TextColor3 = active and CONFIG.Text or CONFIG.SubText
    data.Line.BackgroundTransparency = active and 0 or 1

    if data.Icon:IsA("ImageLabel") then
        data.Icon.ImageColor3 =
            active and CONFIG.Orange or CONFIG.SubText
    end

    if Pages[pageName] then
        Pages[pageName].Visible = active
    end
end

--==================================================
-- INTRO NOTIFICATION
--==================================================

task.delay(0.35, function()
    Notify(
        "RocketUI",
        "Interface carregada com sucesso.",
        CONFIG.Orange
    )
end)

--==================================================
-- MOBILE SCALE
--==================================================

local function UpdateMobile()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    if viewport.X < 700 then
        Window.Size = UDim2.new(
            0.92,
            0,
            0,
            math.min(590, viewport.Y - 40)
        )
    else
        Window.Size = UDim2.fromOffset(940, 590)
    end
end

pcall(UpdateMobile)

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(
    UpdateMobile
)

--==================================================
-- TOUCH FRIENDLY
--==================================================

UIS.TouchEnabled = UIS.TouchEnabled

print("RocketUI loaded.")