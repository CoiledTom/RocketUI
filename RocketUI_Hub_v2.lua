--[[
    RocketUI Hub v2
    CoiledTom / RocketUI

    Foco desta versão: SENSAÇÃO. Tudo tem movimento, resposta ao toque,
    easing gostoso, micro-feedback. Visual Obsidian (preto/grafite + laranja/vermelho).

    - Entrada animada (fade + scale + slide da janela)
    - Sidebar retrátil com spring suave
    - Troca de aba com slide + fade do conteúdo
    - Toggle com spring no knob + glow quando ativo
    - Slider com knob que "respira" ao arrastar (scale up)
    - Botões com ripple de clique + tilt no hover
    - Dropdown com abertura elástica
    - Notificação toast animada (pra feedback de ações)
    - Pulse no dot de status "ONLINE"
    - Drag com inércia leve
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================

local ICONS_URL =
    "https://raw.githubusercontent.com/CoiledTom/RocketUI/refs/heads/main/Icons.lua"

local WINDOW_SIZE = UDim2.fromOffset(580, 400)
local SIDEBAR_EXPANDED = 190
local SIDEBAR_COLLAPSED = 64

local COLOR = {
    Bg = Color3.fromRGB(10, 10, 13),
    Panel = Color3.fromRGB(14, 14, 18),
    Card = Color3.fromRGB(22, 22, 27),
    CardHover = Color3.fromRGB(29, 29, 36),
    Border = Color3.fromRGB(42, 42, 50),

    Text = Color3.fromRGB(235, 235, 240),
    Muted = Color3.fromRGB(128, 128, 138),

    Orange = Color3.fromRGB(255, 120, 20),
    Red = Color3.fromRGB(235, 65, 70),
    Violet = Color3.fromRGB(150, 100, 255),
    Green = Color3.fromRGB(70, 210, 130),
}

local ACCENT = COLOR.Orange -- trocável em runtime (tema)

-- Easings reutilizáveis (dão a sensação "gostosa")
local EASE = {
    Snap = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0),
    Fast = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- ============================================================
-- GUI PARENT
-- ============================================================

local GuiParent
pcall(function()
    if typeof(gethui) == "function" then GuiParent = gethui() end
end)
if not GuiParent then GuiParent = Player:WaitForChild("PlayerGui") end

pcall(function()
    local old = GuiParent:FindFirstChild("RocketUI_Hub")
    if old then old:Destroy() end
end)

-- ============================================================
-- ICONS
-- ============================================================

local Icons = {}

local function LoadIcons()
    local ok, source = pcall(function() return game:HttpGet(ICONS_URL) end)
    if not ok or type(source) ~= "string" then
        warn("[RocketUI] Falha ao baixar Icons.lua")
        return false
    end

    local loader, compileError = loadstring(source)
    if not loader then
        warn("[RocketUI] Erro ao compilar Icons.lua:", compileError)
        return false
    end

    local success, result = pcall(loader)
    if not success or type(result) ~= "table" then
        warn("[RocketUI] Erro ao executar Icons.lua:", result)
        return false
    end

    Icons = result
    return true
end

LoadIcons()

-- ============================================================
-- HELPERS
-- ============================================================

local function New(class, props)
    local obj = Instance.new(class)
    for prop, value in pairs(props or {}) do
        pcall(function() obj[prop] = value end)
    end
    return obj
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLOR.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function Pad(parent, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end

local function Tween(obj, props, info)
    local tw = TweenService:Create(obj, info or EASE.Smooth, props)
    tw:Play()
    return tw
end

local function Icon(parent, name, size, color, pos, anchor)
    local id = Icons[name]

    if id then
        return New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = id,
            ImageColor3 = color or COLOR.Muted,
            Size = size or UDim2.fromOffset(18, 18),
            Position = pos or UDim2.fromOffset(0, 0),
            AnchorPoint = anchor or Vector2.new(0, 0),
            Parent = parent,
        })
    end

    return New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "•",
        TextSize = 16,
        TextColor3 = color or COLOR.Muted,
        Size = size or UDim2.fromOffset(18, 18),
        Position = pos or UDim2.fromOffset(0, 0),
        AnchorPoint = anchor or Vector2.new(0, 0),
        Parent = parent,
    })
end

-- ripple de clique reutilizável em qualquer botão
local function AttachRipple(button, color)
    button.ClipsDescendants = true

    button.MouseButton1Down:Connect(function(x, y)
        local pos = Vector2.new(x, y) - button.AbsolutePosition
        local ripple = New("Frame", {
            BackgroundColor3 = color or COLOR.Text,
            BackgroundTransparency = 0.75,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(pos.X, pos.Y),
            Size = UDim2.fromOffset(0, 0),
            ZIndex = 50,
        })
        ripple.Parent = button
        Corner(ripple, 999)

        local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.8

        Tween(ripple, {
            Size = UDim2.fromOffset(maxSize, maxSize),
            BackgroundTransparency = 1,
        }, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

        task.delay(0.5, function()
            ripple:Destroy()
        end)
    end)
end

-- hover "tilt" sutil (scale up leve)
local function AttachHoverScale(button, scale)
    scale = scale or 1.02
    local baseSize = nil

    button.MouseEnter:Connect(function()
        if not baseSize then baseSize = button.Size end
        Tween(button, {
            Size = UDim2.new(baseSize.X.Scale * scale, baseSize.X.Offset * scale, baseSize.Y.Scale * scale, baseSize.Y.Offset * scale)
        }, EASE.Fast)
    end)

    button.MouseLeave:Connect(function()
        if baseSize then
            Tween(button, {Size = baseSize}, EASE.Fast)
        end
    end)
end

-- ============================================================
-- SCREEN GUI
-- ============================================================

local ScreenGui = New("ScreenGui", {
    Name = "RocketUI_Hub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
})
ScreenGui.Parent = GuiParent

-- backdrop leve pra dar profundidade quando a janela abre
local Backdrop = New("Frame", {
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 0,
})
Backdrop.Parent = ScreenGui

-- ============================================================
-- MAIN WINDOW
-- ============================================================

local Window = New("Frame", {
    Name = "Window",
    BackgroundColor3 = COLOR.Bg,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(0, 0), -- começa em 0 pra animar entrada
    ClipsDescendants = true,
    ZIndex = 1,
})
Window.Parent = ScreenGui
Corner(Window, 16)

local Glow = Stroke(Window, ACCENT, 0.75, 1)

-- entrada animada: fade do backdrop + spring da janela
Tween(Backdrop, {BackgroundTransparency = 0.55}, EASE.Smooth)
Tween(Window, {Size = WINDOW_SIZE}, EASE.Spring)

-- ============================================================
-- TOP BAR
-- ============================================================

local TopBar = New("Frame", {
    BackgroundColor3 = COLOR.Panel,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 42),
})
TopBar.Parent = Window
Corner(TopBar, 16)

New("Frame", {
    BackgroundColor3 = COLOR.Panel,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(0, 22),
    Size = UDim2.new(1, 0, 0, 20),
    Parent = TopBar,
})

local BrandDot = New("Frame", {
    BackgroundColor3 = ACCENT,
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.fromOffset(16, 17),
})
BrandDot.Parent = TopBar
Corner(BrandDot, 4)

-- pulse contínuo no brand dot (respiração)
task.spawn(function()
    while BrandDot.Parent do
        Tween(BrandDot, {Size = UDim2.fromOffset(11, 11)}, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
        task.wait(0.9)
        Tween(BrandDot, {Size = UDim2.fromOffset(8, 8)}, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
        task.wait(0.9)
    end
end)

local BrandText = New("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "ROCKETUI  ·  HUB",
    TextSize = 13,
    TextColor3 = COLOR.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(32, 0),
    Size = UDim2.new(1, -140, 1, 0),
})
BrandText.Parent = TopBar

local StatusPill = New("Frame", {
    BackgroundColor3 = COLOR.Card,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -44, 0.5, 0),
    Size = UDim2.fromOffset(78, 22),
})
StatusPill.Parent = TopBar
Corner(StatusPill, 8)
Stroke(StatusPill, COLOR.Green, 0.6)

local StatusDot = New("Frame", {
    BackgroundColor3 = COLOR.Green,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.fromOffset(8, 11),
    Size = UDim2.fromOffset(6, 6),
})
StatusDot.Parent = StatusPill
Corner(StatusDot, 3)

task.spawn(function()
    while StatusDot.Parent do
        Tween(StatusDot, {BackgroundTransparency = 0.5}, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
        task.wait(0.7)
        Tween(StatusDot, {BackgroundTransparency = 0}, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
        task.wait(0.7)
    end
end)

New("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "ONLINE",
    TextSize = 10,
    TextColor3 = COLOR.Green,
    Position = UDim2.fromOffset(18, 0),
    Size = UDim2.new(1, -22, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = StatusPill,
})

local CloseBtn = New("TextButton", {
    BackgroundColor3 = COLOR.Card,
    AutoButtonColor = false,
    Text = "",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.fromOffset(24, 24),
})
CloseBtn.Parent = TopBar
Corner(CloseBtn, 7)
AttachRipple(CloseBtn, COLOR.Red)
Icon(CloseBtn, "x", UDim2.fromOffset(13, 13), COLOR.Muted, UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = COLOR.Red}, EASE.Fast)
    Tween(CloseBtn, {Rotation = 90}, EASE.Snap)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = COLOR.Card}, EASE.Fast)
    Tween(CloseBtn, {Rotation = 0}, EASE.Snap)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Tween(Window, {Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1}, EASE.Snap)
    Tween(Backdrop, {BackgroundTransparency = 1}, EASE.Snap)
    task.wait(0.18)
    ScreenGui.Enabled = false
end)

-- ============================================================
-- DRAG (com leve inércia)
-- ============================================================

do
    local dragging = false
    local dragStart, startPos
    local lastDelta = Vector2.new(0, 0)

    local function updateInput(input)
        local delta = input.Position - dragStart
        lastDelta = delta
        Window.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            Tween(Window, {Size = WINDOW_SIZE - UDim2.fromOffset(4, 4)}, EASE.Fast)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Tween(Window, {Size = WINDOW_SIZE}, EASE.Spring)
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateInput(input)
        end
    end)
end

-- ============================================================
-- BODY
-- ============================================================

local Body = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 42),
    Size = UDim2.new(1, 0, 1, -42),
})
Body.Parent = Window

local Sidebar = New("Frame", {
    BackgroundColor3 = COLOR.Panel,
    BorderSizePixel = 0,
    Size = UDim2.new(0, SIDEBAR_EXPANDED, 1, 0),
})
Sidebar.Parent = Body

local SideList = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 12),
    Size = UDim2.new(1, -16, 1, -60),
})
SideList.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0, 4)
SideLayout.Parent = SideList

local Collapsed = false
local SideLabels = {}

local CollapseBtn = New("TextButton", {
    BackgroundColor3 = COLOR.Card,
    AutoButtonColor = false,
    Text = "",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 8, 1, -10),
    Size = UDim2.new(1, -16, 0, 32),
})
CollapseBtn.Parent = Sidebar
Corner(CollapseBtn, 8)
Stroke(CollapseBtn, COLOR.Border)
AttachRipple(CollapseBtn)

local CollapseIcon = Icon(CollapseBtn, "chevrons-left", UDim2.fromOffset(15, 15), COLOR.Muted, UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))

local Content = New("Frame", {
    BackgroundColor3 = COLOR.Bg,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(SIDEBAR_EXPANDED, 0),
    Size = UDim2.new(1, -SIDEBAR_EXPANDED, 1, 0),
    ClipsDescendants = true,
})
Content.Parent = Body

New("Frame", {
    BackgroundColor3 = COLOR.Border,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 1, 1, 0),
    Parent = Content,
})

local PagesHolder = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 16),
    Size = UDim2.new(1, -34, 1, -32),
    ClipsDescendants = true,
})
PagesHolder.Parent = Content

-- ============================================================
-- TOAST (feedback visual de ações)
-- ============================================================

local ToastHolder = New("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.fromOffset(220, 200),
    ZIndex = 100,
})
ToastHolder.Parent = Window

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ToastLayout.Padding = UDim.new(0, 6)
ToastLayout.Parent = ToastHolder

local function Toast(text, iconName, color)
    color = color or ACCENT

    local T = New("Frame", {
        BackgroundColor3 = COLOR.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 36),
        ClipsDescendants = true,
        LayoutOrder = os.clock(),
    })
    T.Parent = ToastHolder
    Corner(T, 9)
    local stroke = Stroke(T, color, 0.3)

    if iconName then
        Icon(T, iconName, UDim2.fromOffset(14, 14), color, UDim2.new(0, 10, 0.5, 0), Vector2.new(0, 0.5))
    end

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 12,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(iconName and 32 or 12, 0),
        Size = UDim2.new(1, -40, 1, 0),
        TextTransparency = 1,
    })
    Label.Parent = T

    local targetWidth = math.min(220, 40 + #text * 6.2)
    Tween(T, {Size = UDim2.new(0, targetWidth, 0, 36)}, EASE.Spring)
    task.delay(0.1, function()
        Tween(Label, {TextTransparency = 0}, EASE.Smooth)
    end)

    task.delay(2.2, function()
        if not T.Parent then return end
        Tween(stroke, {Transparency = 1}, EASE.Smooth)
        Tween(Label, {TextTransparency = 1}, EASE.Fast)
        Tween(T, {Size = UDim2.new(0, 0, 0, 36)}, EASE.Snap)
        task.wait(0.18)
        T:Destroy()
    end)
end

-- ============================================================
-- TAB SYSTEM (com slide + fade na troca)
-- ============================================================

local RocketUI = {}
RocketUI.Tabs = {}
RocketUI.Toast = Toast

local currentTabOrder = {}
local tabIndexOf = {}

local function CreatePage(name)
    local page = New("ScrollingFrame", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLOR.Border,
        Visible = false,
    })
    page.Parent = PagesHolder

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = page

    return page
end

local activeTab = nil

local function SelectTab(tabName)
    if activeTab == tabName then return end

    local incoming = RocketUI.Tabs[tabName]
    local outgoing = activeTab and RocketUI.Tabs[activeTab]

    local incomingIdx = tabIndexOf[tabName] or 0
    local outgoingIdx = activeTab and tabIndexOf[activeTab] or 0
    local dir = (incomingIdx > outgoingIdx) and 1 or -1

    -- estado visual da sidebar
    for name, data in pairs(RocketUI.Tabs) do
        local active = name == tabName
        local targetColor = active and ACCENT or COLOR.Muted

        if data.Icon:IsA("ImageLabel") then
            Tween(data.Icon, {ImageColor3 = targetColor}, EASE.Fast)
        else
            Tween(data.Icon, {TextColor3 = targetColor}, EASE.Fast)
        end

        Tween(data.Label, {TextColor3 = active and COLOR.Text or COLOR.Muted}, EASE.Fast)
        Tween(data.Accent, {Transparency = active and 0 or 1}, EASE.Fast)
        Tween(data.Button, {BackgroundTransparency = active and 0 or 1}, EASE.Fast)
    end

    -- animação de página: slide out da atual, slide in da nova
    if outgoing then
        local out = outgoing.Page
        Tween(out, {
            Position = UDim2.fromScale(dir * -0.06, 0),
        }, EASE.Fast)
        local outTween = Tween(out, {}, EASE.Fast)
        task.delay(0.12, function()
            out.Visible = false
            out.Position = UDim2.fromScale(0, 0)
        end)
    end

    incoming.Page.Position = UDim2.fromScale(dir * 0.06, 0)
    incoming.Page.Visible = true

    -- fade manual via CanvasGroup não é garantido em todo client; usamos posição + leve delay
    Tween(incoming.Page, {Position = UDim2.fromScale(0, 0)}, EASE.Smooth)

    activeTab = tabName
end

local tabOrder = 0
local function AddTab(name, iconName)
    tabOrder += 1
    tabIndexOf[name] = tabOrder

    local Button = New("TextButton", {
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, 38),
        LayoutOrder = tabOrder,
        ClipsDescendants = true,
    })
    Button.Parent = SideList
    Corner(Button, 9)
    AttachRipple(Button)

    local Accent = New("Frame", {
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(3, 18),
    })
    Accent.Parent = Button
    Corner(Accent, 2)

    local TabIcon = Icon(Button, iconName, UDim2.fromOffset(17, 17), COLOR.Muted, UDim2.new(0, 14, 0.5, 0), Vector2.new(0, 0.5))

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextSize = 13,
        TextColor3 = COLOR.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -50, 1, 0),
    })
    Label.Parent = Button
    table.insert(SideLabels, Label)

    local Page = CreatePage(name)

    local PageTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = name,
        TextSize = 20,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 26),
        LayoutOrder = 0,
    })
    PageTitle.Parent = Page

    RocketUI.Tabs[name] = {
        Button = Button, Icon = TabIcon, Label = Label, Accent = Accent, Page = Page,
    }

    Button.MouseEnter:Connect(function()
        if activeTab ~= name then
            Tween(Button, {BackgroundTransparency = 0.6}, EASE.Fast)
        end
        Tween(TabIcon, {Position = UDim2.new(0, 17, 0.5, 0)}, EASE.Fast)
    end)
    Button.MouseLeave:Connect(function()
        if activeTab ~= name then
            Tween(Button, {BackgroundTransparency = 1}, EASE.Fast)
        end
        Tween(TabIcon, {Position = UDim2.new(0, 14, 0.5, 0)}, EASE.Fast)
    end)
    Button.MouseButton1Click:Connect(function()
        SelectTab(name)
    end)

    return Page
end

-- ============================================================
-- COLLAPSE LOGIC
-- ============================================================

CollapseBtn.MouseButton1Click:Connect(function()
    Collapsed = not Collapsed
    local w = Collapsed and SIDEBAR_COLLAPSED or SIDEBAR_EXPANDED

    Tween(Sidebar, {Size = UDim2.new(0, w, 1, 0)}, EASE.Spring)
    Tween(Content, {Position = UDim2.fromOffset(w, 0), Size = UDim2.new(1, -w, 1, 0)}, EASE.Spring)
    Tween(CollapseIcon, {Rotation = Collapsed and 180 or 0}, EASE.Spring)

    for _, label in ipairs(SideLabels) do
        Tween(label, {TextTransparency = Collapsed and 1 or 0}, EASE.Fast)
    end
end)

-- ============================================================
-- COMPONENT LIBRARY (todos animados)
-- ============================================================

local function SectionCard(parent, title, order)
    local Card = New("Frame", {
        BackgroundColor3 = COLOR.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order or 0,
        ClipsDescendants = true,
    })
    Card.Parent = parent
    Corner(Card, 12)
    local stroke = Stroke(Card, COLOR.Border)
    Pad(Card, 14, 12, 14, 12)

    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 10)
    Layout.Parent = Card

    -- leve glow ao passar o mouse no card inteiro
    Card.MouseEnter:Connect(function()
        Tween(stroke, {Color = ACCENT, Transparency = 0.5}, EASE.Smooth)
    end)
    Card.MouseLeave:Connect(function()
        Tween(stroke, {Color = COLOR.Border, Transparency = 0}, EASE.Smooth)
    end)

    if title then
        local Title = New("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = title:upper(),
            TextSize = 11,
            TextColor3 = ACCENT,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 14),
            LayoutOrder = -1,
        })
        Title.Parent = Card
    end

    return Card
end

function RocketUI:Toggle(parent, text, default, iconName, callback)
    local state = default or false

    local Row = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
    })
    Row.Parent = parent

    local RowIcon
    if iconName then
        RowIcon = Icon(Row, iconName, UDim2.fromOffset(15, 15), state and ACCENT or COLOR.Muted, UDim2.new(0, 0, 0.5, 0), Vector2.new(0, 0.5))
    end

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(iconName and 24 or 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Parent = Row,
    })

    local Switch = New("TextButton", {
        BackgroundColor3 = state and ACCENT or COLOR.Border,
        AutoButtonColor = false,
        Text = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(40, 22),
    })
    Switch.Parent = Row
    Corner(Switch, 11)
    local switchGlow = Stroke(Switch, ACCENT, state and 0.4 or 1, 1)

    local Knob = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
    })
    Knob.Parent = Switch
    Corner(Knob, 9)

    local function applyVisual(animated)
        local info = animated and EASE.Spring or nil
        if animated then
            Tween(Switch, {BackgroundColor3 = state and ACCENT or COLOR.Border}, EASE.Smooth)
            Tween(switchGlow, {Transparency = state and 0.4 or 1}, EASE.Smooth)
            Tween(Knob, {Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)}, EASE.Spring)
            if RowIcon then
                if RowIcon:IsA("ImageLabel") then
                    Tween(RowIcon, {ImageColor3 = state and ACCENT or COLOR.Muted}, EASE.Smooth)
                else
                    Tween(RowIcon, {TextColor3 = state and ACCENT or COLOR.Muted}, EASE.Smooth)
                end
            end
        else
            Switch.BackgroundColor3 = state and ACCENT or COLOR.Border
            switchGlow.Transparency = state and 0.4 or 1
            Knob.Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        end
    end

    Switch.MouseButton1Click:Connect(function()
        state = not state
        -- squash rápido no knob pra dar sensação de "clique"
        Tween(Knob, {Size = UDim2.fromOffset(14, 18)}, EASE.Fast)
        task.delay(0.08, function()
            Tween(Knob, {Size = UDim2.fromOffset(18, 18)}, EASE.Spring)
        end)
        applyVisual(true)
        if callback then task.spawn(callback, state) end
    end)

    Switch.MouseEnter:Connect(function()
        Tween(Switch, {Size = UDim2.fromOffset(42, 23)}, EASE.Fast)
    end)
    Switch.MouseLeave:Connect(function()
        Tween(Switch, {Size = UDim2.fromOffset(40, 22)}, EASE.Fast)
    end)

    return {
        Set = function(_, value)
            state = value
            applyVisual(true)
        end,
        Get = function() return state end,
    }
end

function RocketUI:Slider(parent, text, min, max, default, callback)
    min, max = min or 0, max or 100
    local value = math.clamp(default or min, min, max)

    local Row = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
    })
    Row.Parent = parent

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -50, 0, 16),
        Parent = Row,
    })

    local ValueLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(value),
        TextSize = 13,
        TextColor3 = ACCENT,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(40, 16),
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    ValueLabel.Parent = Row

    local Track = New("Frame", {
        BackgroundColor3 = COLOR.Border,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 6),
    })
    Track.Parent = Row
    Corner(Track, 3)

    local function ratio(v) return (v - min) / (max - min) end

    local Fill = New("Frame", {
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        Size = UDim2.new(ratio(value), 0, 1, 0),
    })
    Fill.Parent = Track
    Corner(Fill, 3)

    local Knob = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(ratio(value), 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        ZIndex = 2,
    })
    Knob.Parent = Track
    Corner(Knob, 7)
    local knobStroke = Stroke(Knob, ACCENT, 0, 2)

    local dragging = false

    local function update(inputPos, animated)
        local rel = math.clamp((inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        local info = animated and EASE.Fast or nil
        if animated then
            Tween(Fill, {Size = UDim2.new(rel, 0, 1, 0)}, EASE.Fast)
            Tween(Knob, {Position = UDim2.new(rel, 0, 0.5, 0)}, EASE.Fast)
        else
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Knob.Position = UDim2.new(rel, 0, 0.5, 0)
        end
        ValueLabel.Text = tostring(value)
        if callback then task.spawn(callback, value) end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Tween(Knob, {Size = UDim2.fromOffset(18, 18)}, EASE.Fast)
            Tween(knobStroke, {Thickness = 3}, EASE.Fast)
            update(input.Position, false)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position, false)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                Tween(Knob, {Size = UDim2.fromOffset(14, 14)}, EASE.Spring)
                Tween(knobStroke, {Thickness = 2}, EASE.Fast)
            end
        end
    end)

    return {
        Set = function(_, v)
            v = math.clamp(v, min, max)
            value = v
            local r = ratio(v)
            Tween(Fill, {Size = UDim2.new(r, 0, 1, 0)}, EASE.Smooth)
            Tween(Knob, {Position = UDim2.new(r, 0, 0.5, 0)}, EASE.Smooth)
            ValueLabel.Text = tostring(v)
        end,
        Get = function() return value end,
    }
end

function RocketUI:Button(parent, text, iconName, callback)
    local Btn = New("TextButton", {
        BackgroundColor3 = COLOR.Card,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        ClipsDescendants = true,
    })
    Btn.Parent = parent
    Corner(Btn, 9)
    local stroke = Stroke(Btn, COLOR.Border)
    AttachRipple(Btn, ACCENT)

    local BtnIcon
    if iconName then
        BtnIcon = Icon(Btn, iconName, UDim2.fromOffset(15, 15), ACCENT, UDim2.new(0, 12, 0.5, 0), Vector2.new(0, 0.5))
    end

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextColor3 = COLOR.Text,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.fromOffset(iconName and 34 or 12, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Btn,
    })

    Btn.MouseEnter:Connect(function()
        Tween(Btn, {BackgroundColor3 = COLOR.CardHover}, EASE.Fast)
        Tween(stroke, {Color = ACCENT, Transparency = 0.4}, EASE.Fast)
        if BtnIcon then Tween(BtnIcon, {Position = UDim2.new(0, 15, 0.5, 0)}, EASE.Fast) end
    end)
    Btn.MouseLeave:Connect(function()
        Tween(Btn, {BackgroundColor3 = COLOR.Card}, EASE.Fast)
        Tween(stroke, {Color = COLOR.Border, Transparency = 0}, EASE.Fast)
        if BtnIcon then Tween(BtnIcon, {Position = UDim2.new(0, 12, 0.5, 0)}, EASE.Fast) end
    end)
    Btn.MouseButton1Click:Connect(function()
        Tween(Btn, {Size = UDim2.new(1, 0, 0, 31)}, EASE.Fast)
        task.delay(0.08, function()
            Tween(Btn, {Size = UDim2.new(1, 0, 0, 34)}, EASE.Spring)
        end)
        if callback then task.spawn(callback) end
    end)

    return Btn
end

function RocketUI:Dropdown(parent, text, options, default, callback)
    local selected = default or options[1]
    local open = false

    local Row = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
    })
    Row.Parent = parent

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 16),
        Parent = Row,
    })

    local Head = New("TextButton", {
        BackgroundColor3 = COLOR.Bg,
        AutoButtonColor = false,
        Text = "",
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, 0, 0, 32),
    })
    Head.Parent = Row
    Corner(Head, 8)
    local headStroke = Stroke(Head, COLOR.Border)

    local SelectedLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = tostring(selected),
        TextSize = 13,
        TextColor3 = selected and COLOR.Text or COLOR.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -36, 1, 0),
    })
    SelectedLabel.Parent = Head

    local Chevron = Icon(Head, "chevron-down", UDim2.fromOffset(14, 14), COLOR.Muted, UDim2.new(1, -12, 0.5, 0), Vector2.new(1, 0.5))

    local ListFrame = New("Frame", {
        BackgroundColor3 = COLOR.Bg,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 58),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 5,
    })
    ListFrame.Parent = Row
    Corner(ListFrame, 8)
    Stroke(ListFrame, ACCENT, 0.5)

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ListFrame

    for i, opt in ipairs(options) do
        local OptBtn = New("TextButton", {
            BackgroundColor3 = ACCENT,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = i,
            ZIndex = 6,
        })
        OptBtn.Parent = ListFrame

        New("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = tostring(opt),
            TextSize = 12,
            TextColor3 = COLOR.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -20, 1, 0),
            ZIndex = 6,
            Parent = OptBtn,
        })

        OptBtn.MouseEnter:Connect(function() Tween(OptBtn, {BackgroundTransparency = 0.85}, EASE.Fast) end)
        OptBtn.MouseLeave:Connect(function() Tween(OptBtn, {BackgroundTransparency = 1}, EASE.Fast) end)

        OptBtn.MouseButton1Click:Connect(function()
            selected = opt
            SelectedLabel.Text = tostring(opt)
            SelectedLabel.TextColor3 = COLOR.Text
            open = false
            Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, EASE.Snap)
            Tween(Chevron, {Rotation = 0}, EASE.Snap)
            Tween(headStroke, {Color = COLOR.Border}, EASE.Smooth)
            task.delay(0.16, function() ListFrame.Visible = false end)
            if callback then task.spawn(callback, opt) end
        end)
    end

    Head.MouseButton1Click:Connect(function()
        open = not open
        ListFrame.Visible = true
        local targetH = open and math.min(#options * 30, 150) or 0
        Tween(ListFrame, {Size = UDim2.new(1, 0, 0, targetH)}, EASE.Elastic)
        Tween(Chevron, {Rotation = open and 180 or 0}, EASE.Spring)
        Tween(headStroke, {Color = open and ACCENT or COLOR.Border, Transparency = open and 0.3 or 0}, EASE.Smooth)
        if not open then
            task.delay(0.2, function()
                if not open then ListFrame.Visible = false end
            end)
        end
    end)

    Head.MouseEnter:Connect(function()
        if not open then Tween(headStroke, {Transparency = 0.4}, EASE.Fast) end
    end)
    Head.MouseLeave:Connect(function()
        if not open then Tween(headStroke, {Transparency = 0}, EASE.Fast) end
    end)

    return { Get = function() return selected end }
end

function RocketUI:Label(parent, text, muted)
    local Lbl = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 12,
        TextColor3 = muted and COLOR.Muted or COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    Lbl.Parent = parent
    return Lbl
end

RocketUI.SectionCard = SectionCard

-- ============================================================
-- PÁGINAS DE EXEMPLO
-- ============================================================

local HomePage = AddTab("Home", "house")
do
    local Welcome = SectionCard(HomePage, "Bem-vindo", 1)
    RocketUI:Label(Welcome, "RocketUI Hub carregado. Navegue pelas abas ao lado — tudo aqui responde ao toque.", true)

    local Info = SectionCard(HomePage, "Status", 2)
    local pingLabel = RocketUI:Label(Info, "Ping: calculando...", false)
    task.spawn(function()
        while ScreenGui.Parent do
            local ok, ping = pcall(function() return math.floor(Player:GetNetworkPing() * 1000) end)
            pingLabel.Text = "Ping: " .. (ok and (ping .. " ms") or "N/A")
            task.wait(1)
        end
    end)

    local Quick = SectionCard(HomePage, "Ações Rápidas", 3)
    RocketUI:Button(Quick, "Recarregar Ícones", "refresh-cw", function()
        LoadIcons()
        Toast("Ícones recarregados", "check", COLOR.Green)
    end)
end

local CombatPage = AddTab("Combat", "sword")
do
    local Aim = SectionCard(CombatPage, "Aimbot", 1)
    RocketUI:Toggle(Aim, "Ativar Aimbot", false, "crosshair", function(state)
        Toast(state and "Aimbot ativado" or "Aimbot desativado", "crosshair")
    end)
    RocketUI:Slider(Aim, "FOV", 10, 200, 90)
    RocketUI:Dropdown(Aim, "Parte do corpo", {"Head", "Torso", "HumanoidRootPart"}, "Head")

    local Combat = SectionCard(CombatPage, "Combate Geral", 2)
    RocketUI:Toggle(Combat, "Auto Parry", false, "shield")
    RocketUI:Toggle(Combat, "Kill Aura", false, "flame")
end

local VisualsPage = AddTab("Visuals", "eye")
do
    local Esp = SectionCard(VisualsPage, "ESP", 1)
    RocketUI:Toggle(Esp, "Players ESP", false, "users")
    RocketUI:Toggle(Esp, "Chams", false, "sparkles")
    RocketUI:Slider(Esp, "Transparência", 0, 100, 50)

    local Env = SectionCard(VisualsPage, "Ambiente", 2)
    RocketUI:Toggle(Env, "Fullbright", false, "sun")
    RocketUI:Slider(Env, "Field of View", 70, 120, 90)
end

local MiscPage = AddTab("Misc", "layout-grid")
do
    local Movement = SectionCard(MiscPage, "Movimento", 1)
    RocketUI:Toggle(Movement, "Infinite Jump", false, "arrow-up")
    RocketUI:Slider(Movement, "Walk Speed", 16, 200, 16)
    RocketUI:Slider(Movement, "Jump Power", 50, 300, 50)

    local Utils = SectionCard(MiscPage, "Utilidades", 2)
    RocketUI:Button(Utils, "Copiar Coordenadas", "copy", function()
        Toast("Coordenadas copiadas", "copy", COLOR.Violet)
    end)
    RocketUI:Button(Utils, "Servidor Aleatório", "shuffle", function()
        Toast("Trocando de servidor...", "shuffle")
    end)
end

local SettingsPage = AddTab("Settings", "settings")
do
    local UiSettings = SectionCard(SettingsPage, "Interface", 1)
    RocketUI:Slider(UiSettings, "Transparência do Menu", 0, 50, 5, function(v)
        Tween(Window, {BackgroundTransparency = v / 100}, EASE.Fast)
    end)
    RocketUI:Dropdown(UiSettings, "Tema de Destaque", {"Laranja", "Vermelho", "Violeta"}, "Laranja", function(v)
        local map = {Laranja = COLOR.Orange, Vermelho = COLOR.Red, Violeta = COLOR.Violet}
        ACCENT = map[v]
        Tween(Glow, {Color = ACCENT}, EASE.Smooth)
        Tween(BrandDot, {BackgroundColor3 = ACCENT}, EASE.Smooth)
        for _, data in pairs(RocketUI.Tabs) do
            data.Accent.BackgroundColor3 = ACCENT
            if data.Page.Visible then
                if data.Icon:IsA("ImageLabel") then data.Icon.ImageColor3 = ACCENT
                else data.Icon.TextColor3 = ACCENT end
            end
        end
        Toast("Tema alterado para " .. v, "palette", ACCENT)
    end)

    local About = SectionCard(SettingsPage, "Sobre", 2)
    RocketUI:Label(About, "RocketUI Hub — desenvolvido por CoiledTom.", true)
    RocketUI:Label(About, "Ícones via Footagesus/Icons (Lucide, Solar, Geist, Craft, Gravity, SF Symbols).", true)
end

-- ============================================================
-- INIT
-- ============================================================

SelectTab("Home")

print("[RocketUI] Hub v2 carregado com animações!")

return RocketUI
