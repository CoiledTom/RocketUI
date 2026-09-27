--[[
    RocketUI Hub v3 — "Dashboard Style"
    CoiledTom / RocketUI

    Referência visual: dashboards dark modernos (cards flat, bordas quase
    invisíveis, fundo levemente translúcido, badges de tendência, tipografia leve).

    Mudanças em relação à v2:
    - Visual: cards mais "flat", transparência sutil no painel, bordas quase
      invisíveis, tipografia leve (Gotham/GothamMedium, menos Bold)
    - Badges de tendência (verde ↑ / vermelho ↓) como no dashboard de referência
    - Stat cards estilo "Leads / Conversion / CLV"
    - Mini gráfico de linha (Revenue over time) usando Frames (sem depender de nada externo)
    - Animações SIMPLES: fade + slide curto em tudo. Sem ripple, sem squash,
      sem elastic. Só easing suave e consistente.
    - Mobile-friendly: sidebar colapsa pra ícones, drag por toque, áreas de
      toque generosas.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================

local ICONS_URL =
    "https://raw.githubusercontent.com/CoiledTom/RocketUI/refs/heads/main/Icons.lua"

local WINDOW_SIZE = UDim2.fromOffset(620, 420)
local SIDEBAR_EXPANDED = 176
local SIDEBAR_COLLAPSED = 60

local COLOR = {
    -- fundo com leve transparência (simulando glass) via BackgroundTransparency
    Bg = Color3.fromRGB(15, 15, 18),
    Panel = Color3.fromRGB(19, 19, 23),
    Card = Color3.fromRGB(24, 24, 29),
    CardHover = Color3.fromRGB(29, 29, 35),
    Border = Color3.fromRGB(38, 38, 45),

    Text = Color3.fromRGB(230, 230, 235),
    SubText = Color3.fromRGB(160, 160, 168),
    Muted = Color3.fromRGB(110, 110, 120),

    Orange = Color3.fromRGB(255, 130, 40),
    Red = Color3.fromRGB(235, 80, 85),
    Violet = Color3.fromRGB(160, 110, 255),
    Green = Color3.fromRGB(80, 210, 140),
}

local ACCENT = COLOR.Orange

-- easing único e consistente = sensação fluida, sem exagero
local EASE = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EASE_SLOW = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
    local loader, err = loadstring(source)
    if not loader then
        warn("[RocketUI] Erro ao compilar Icons.lua:", err)
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
    local tw = TweenService:Create(obj, info or EASE, props)
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
            Size = size or UDim2.fromOffset(16, 16),
            Position = pos or UDim2.fromOffset(0, 0),
            AnchorPoint = anchor or Vector2.new(0, 0),
            Parent = parent,
        })
    end
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "•",
        TextSize = 14,
        TextColor3 = color or COLOR.Muted,
        Size = size or UDim2.fromOffset(16, 16),
        Position = pos or UDim2.fromOffset(0, 0),
        AnchorPoint = anchor or Vector2.new(0, 0),
        Parent = parent,
    })
end

-- fade+slide simples pra qualquer elemento que "aparece"
local function FadeIn(obj, offsetY)
    offsetY = offsetY or 6
    local goalPos = obj.Position
    obj.Position = goalPos + UDim2.fromOffset(0, offsetY)
    Tween(obj, {Position = goalPos}, EASE_SLOW)
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

local Backdrop = New("Frame", {
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 0,
})
Backdrop.Parent = ScreenGui

-- ============================================================
-- MAIN WINDOW (com transparência sutil tipo glass)
-- ============================================================

local Window = New("Frame", {
    Name = "Window",
    BackgroundColor3 = COLOR.Bg,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.52, 0),
    Size = UDim2.fromOffset(WINDOW_SIZE.X.Offset, 0),
    ClipsDescendants = true,
    ZIndex = 1,
})
Window.Parent = ScreenGui
Corner(Window, 14)
Stroke(Window, COLOR.Border, 0.3)

Tween(Backdrop, {BackgroundTransparency = 0.65}, EASE_SLOW)
Tween(Window, {Size = WINDOW_SIZE, Position = UDim2.new(0.5, 0, 0.5, 0)}, EASE_SLOW)

-- ============================================================
-- TOP BAR
-- ============================================================

local TopBar = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 46),
})
TopBar.Parent = Window

local BrandIcon = New("Frame", {
    BackgroundColor3 = ACCENT,
    Position = UDim2.fromOffset(18, 15),
    Size = UDim2.fromOffset(16, 16),
})
BrandIcon.Parent = TopBar
Corner(BrandIcon, 5)

local BrandText = New("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "RocketUI",
    TextSize = 15,
    TextColor3 = COLOR.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(42, 0),
    Size = UDim2.new(1, -160, 1, 0),
})
BrandText.Parent = TopBar

local StatusPill = New("Frame", {
    BackgroundColor3 = COLOR.Card,
    BackgroundTransparency = 0.2,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -46, 0.5, 0),
    Size = UDim2.fromOffset(72, 24),
})
StatusPill.Parent = TopBar
Corner(StatusPill, 8)

local StatusDot = New("Frame", {
    BackgroundColor3 = COLOR.Green,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.fromOffset(10, 12),
    Size = UDim2.fromOffset(6, 6),
})
StatusDot.Parent = StatusPill
Corner(StatusDot, 3)

New("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Online",
    TextSize = 11,
    TextColor3 = COLOR.SubText,
    Position = UDim2.fromOffset(20, 0),
    Size = UDim2.new(1, -24, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = StatusPill,
})

-- pulso simples, só transparência (sem scale)
task.spawn(function()
    while StatusDot.Parent do
        Tween(StatusDot, {BackgroundTransparency = 0.55}, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
        task.wait(1)
        Tween(StatusDot, {BackgroundTransparency = 0}, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
        task.wait(1)
    end
end)

local CloseBtn = New("TextButton", {
    BackgroundColor3 = COLOR.Card,
    BackgroundTransparency = 0.2,
    AutoButtonColor = false,
    Text = "",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(26, 26),
})
CloseBtn.Parent = TopBar
Corner(CloseBtn, 7)
Icon(CloseBtn, "x", UDim2.fromOffset(13, 13), COLOR.SubText, UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = COLOR.Red, BackgroundTransparency = 0.3}, EASE)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = COLOR.Card, BackgroundTransparency = 0.2}, EASE)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Tween(Window, {BackgroundTransparency = 1, Size = UDim2.fromOffset(WINDOW_SIZE.X.Offset, 0)}, EASE)
    Tween(Backdrop, {BackgroundTransparency = 1}, EASE)
    task.wait(0.22)
    ScreenGui.Enabled = false
end)

-- ============================================================
-- DRAG
-- ============================================================

do
    local dragging = false
    local dragStart, startPos

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- BODY
-- ============================================================

local Body = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 46),
    Size = UDim2.new(1, 0, 1, -46),
})
Body.Parent = Window

-- ---------------- Sidebar ----------------

local Sidebar = New("Frame", {
    BackgroundColor3 = COLOR.Panel,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Size = UDim2.new(0, SIDEBAR_EXPANDED, 1, 0),
})
Sidebar.Parent = Body

-- busca (estético, decorativo — dá a sensação do dashboard)
local SearchBox = New("Frame", {
    BackgroundColor3 = COLOR.Card,
    BackgroundTransparency = 0.2,
    Position = UDim2.fromOffset(10, 12),
    Size = UDim2.new(1, -20, 0, 30),
})
SearchBox.Parent = Sidebar
Corner(SearchBox, 8)
Icon(SearchBox, "search", UDim2.fromOffset(13, 13), COLOR.Muted, UDim2.new(0, 10, 0.5, 0), Vector2.new(0, 0.5))
local SearchLabel = New("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Search...",
    TextSize = 12,
    TextColor3 = COLOR.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(32, 0),
    Size = UDim2.new(1, -40, 1, 0),
})
SearchLabel.Parent = SearchBox

local SectionLabel = New("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "PLATFORM",
    TextSize = 10,
    TextColor3 = COLOR.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(14, 52),
    Size = UDim2.new(1, -24, 0, 14),
})
SectionLabel.Parent = Sidebar

local SideList = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 70),
    Size = UDim2.new(1, -16, 1, -130),
})
SideList.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0, 2)
SideLayout.Parent = SideList

local Collapsed = false
local SideLabels = {SearchLabel, SectionLabel}

local CollapseBtn = New("TextButton", {
    BackgroundColor3 = COLOR.Card,
    BackgroundTransparency = 0.2,
    AutoButtonColor = false,
    Text = "",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 8, 1, -10),
    Size = UDim2.new(1, -16, 0, 30),
})
CollapseBtn.Parent = Sidebar
Corner(CollapseBtn, 8)
local CollapseIcon = Icon(CollapseBtn, "chevrons-left", UDim2.fromOffset(14, 14), COLOR.Muted, UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))

CollapseBtn.MouseEnter:Connect(function() Tween(CollapseBtn, {BackgroundTransparency = 0}, EASE) end)
CollapseBtn.MouseLeave:Connect(function() Tween(CollapseBtn, {BackgroundTransparency = 0.2}, EASE) end)

-- ---------------- Content ----------------

local Content = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(SIDEBAR_EXPANDED, 0),
    Size = UDim2.new(1, -SIDEBAR_EXPANDED, 1, 0),
    ClipsDescendants = true,
})
Content.Parent = Body

local PagesHolder = New("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 16),
    Size = UDim2.new(1, -36, 1, -30),
    ClipsDescendants = true,
})
PagesHolder.Parent = Content

-- ============================================================
-- TOAST simples (fade, sem bounce)
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
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, math.min(220, 40 + #text * 6.2), 0, 34),
        LayoutOrder = os.clock(),
    })
    T.Parent = ToastHolder
    Corner(T, 8)
    local stroke = Stroke(T, color, 0.5)

    if iconName then
        Icon(T, iconName, UDim2.fromOffset(13, 13), color, UDim2.new(0, 10, 0.5, 0), Vector2.new(0, 0.5))
    end

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 12,
        TextColor3 = COLOR.Text,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(iconName and 30 or 12, 0),
        Size = UDim2.new(1, -38, 1, 0),
    })
    Label.Parent = T

    Tween(T, {BackgroundTransparency = 0.15}, EASE)
    Tween(Label, {TextTransparency = 0}, EASE)

    task.delay(2.2, function()
        if not T.Parent then return end
        Tween(T, {BackgroundTransparency = 1}, EASE)
        Tween(stroke, {Transparency = 1}, EASE)
        Tween(Label, {TextTransparency = 1}, EASE)
        task.wait(0.22)
        T:Destroy()
    end)
end

-- ============================================================
-- TAB SYSTEM (fade simples entre páginas)
-- ============================================================

local RocketUI = {}
RocketUI.Tabs = {}
RocketUI.Toast = Toast

local function CreatePage(name)
    local page = New("ScrollingFrame", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
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

    for name, data in pairs(RocketUI.Tabs) do
        local active = name == tabName
        local targetColor = active and ACCENT or COLOR.Muted

        if data.Icon:IsA("ImageLabel") then
            Tween(data.Icon, {ImageColor3 = targetColor}, EASE)
        else
            Tween(data.Icon, {TextColor3 = targetColor}, EASE)
        end

        Tween(data.Label, {TextColor3 = active and COLOR.Text or COLOR.SubText}, EASE)
        Tween(data.Button, {BackgroundTransparency = active and 0.1 or 1}, EASE)

        if active then
            data.Page.Visible = true
            data.Page.GroupTransparency = 1
        elseif data.Page.Visible then
            -- esconde a antiga com leve delay pro fade não "cortar"
            local pg = data.Page
            task.delay(0.15, function()
                if activeTab ~= name then pg.Visible = false end
            end)
        end
    end

    activeTab = tabName
end

local tabOrder = 0
local function AddTab(name, iconName)
    tabOrder += 1

    local Button = New("TextButton", {
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = tabOrder,
    })
    Button.Parent = SideList
    Corner(Button, 8)

    local TabIcon = Icon(Button, iconName, UDim2.fromOffset(16, 16), COLOR.Muted, UDim2.new(0, 14, 0.5, 0), Vector2.new(0, 0.5))

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextSize = 13,
        TextColor3 = COLOR.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -48, 1, 0),
    })
    Label.Parent = Button
    table.insert(SideLabels, Label)

    local Page = CreatePage(name)

    local PageTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextSize = 19,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 26),
        LayoutOrder = 0,
    })
    PageTitle.Parent = Page

    RocketUI.Tabs[name] = {Button = Button, Icon = TabIcon, Label = Label, Page = Page}

    Button.MouseEnter:Connect(function()
        if activeTab ~= name then Tween(Button, {BackgroundTransparency = 0.6}, EASE) end
    end)
    Button.MouseLeave:Connect(function()
        if activeTab ~= name then Tween(Button, {BackgroundTransparency = 1}, EASE) end
    end)
    Button.MouseButton1Click:Connect(function() SelectTab(name) end)

    return Page
end

-- ============================================================
-- COLLAPSE
-- ============================================================

CollapseBtn.MouseButton1Click:Connect(function()
    Collapsed = not Collapsed
    local w = Collapsed and SIDEBAR_COLLAPSED or SIDEBAR_EXPANDED

    Tween(Sidebar, {Size = UDim2.new(0, w, 1, 0)}, EASE_SLOW)
    Tween(Content, {Position = UDim2.fromOffset(w, 0), Size = UDim2.new(1, -w, 1, 0)}, EASE_SLOW)
    Tween(CollapseIcon, {Rotation = Collapsed and 180 or 0}, EASE_SLOW)

    for _, label in ipairs(SideLabels) do
        Tween(label, {TextTransparency = Collapsed and 1 or 0}, EASE)
    end
    Tween(SearchBox, {BackgroundTransparency = Collapsed and 1 or 0.2}, EASE)
end)

-- ============================================================
-- COMPONENTES ESTILO DASHBOARD
-- ============================================================

-- Card genérico (usado por baixo de tudo)
local function Card(parent, order, height)
    local C = New("Frame", {
        BackgroundColor3 = COLOR.Card,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = height and UDim2.new(1, 0, 0, height) or UDim2.new(1, 0, 0, 0),
        AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        LayoutOrder = order or 0,
    })
    C.Parent = parent
    Corner(C, 12)
    Stroke(C, COLOR.Border, 0.3)
    return C
end

-- Stat card tipo "Leads / Conversion Rate / CLV" com badge de tendência
function RocketUI:StatCard(parent, label, value, deltaText, trend, order)
    -- trend: "up" | "down"
    local C = Card(parent, order, 78)
    Pad(C, 14, 12, 14, 10)

    local Top = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16)})
    Top.Parent = C

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = label,
        TextSize = 12,
        TextColor3 = COLOR.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 1, 0),
        Parent = Top,
    })

    local trendColor = trend == "down" and COLOR.Red or COLOR.Green
    local Badge = New("Frame", {
        BackgroundColor3 = trendColor,
        BackgroundTransparency = 0.85,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(52, 18),
        Parent = Top,
    })
    Corner(Badge, 6)
    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = (trend == "down" and "▼ " or "▲ ") .. deltaText,
        TextSize = 10,
        TextColor3 = trendColor,
        Size = UDim2.fromScale(1, 1),
        Parent = Badge,
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = value,
        TextSize = 24,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 30),
        Parent = C,
    })

    return C
end

-- Mini gráfico de linha (revenue over time) desenhado com Frames rotacionados
function RocketUI:LineChart(parent, points, order, height)
    height = height or 130
    local C = Card(parent, order, height + 40)
    Pad(C, 16, 14, 16, 14)

    local Header = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16)})
    Header.Parent = C
    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Revenue over time",
        TextSize = 12,
        TextColor3 = COLOR.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = Header,
    })

    local ChartArea = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 26),
        Size = UDim2.new(1, 0, 0, height),
        ClipsDescendants = false,
    })
    ChartArea.Parent = C

    local maxV, minV = -math.huge, math.huge
    for _, v in ipairs(points) do
        maxV = math.max(maxV, v)
        minV = math.min(minV, v)
    end
    if maxV == minV then maxV = minV + 1 end

    task.defer(function()
        local w = ChartArea.AbsoluteSize.X
        local h = ChartArea.AbsoluteSize.Y
        if w <= 0 then return end

        local step = w / (#points - 1)
        local prev

        for i, v in ipairs(points) do
            local x = (i - 1) * step
            local y = h - ((v - minV) / (maxV - minV)) * h

            if prev then
                local dx = x - prev.x
                local dy = y - prev.y
                local length = math.sqrt(dx * dx + dy * dy)
                local angle = math.deg(math.atan2(dy, dx))

                local Seg = New("Frame", {
                    BackgroundColor3 = ACCENT,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromOffset(prev.x, prev.y),
                    Size = UDim2.fromOffset(length, 2),
                    Rotation = angle,
                    ZIndex = 3,
                })
                Seg.Parent = ChartArea
                Corner(Seg, 1)
            end

            prev = {x = x, y = y}
        end

        -- ponto final destacado
        local Dot = New("Frame", {
            BackgroundColor3 = ACCENT,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(prev.x, prev.y),
            Size = UDim2.fromOffset(8, 8),
            ZIndex = 4,
        })
        Dot.Parent = ChartArea
        Corner(Dot, 4)
        Stroke(Dot, COLOR.Bg, 0, 2)
    end)

    return C
end

function RocketUI:Toggle(parent, text, default, iconName, callback)
    local state = default or false

    local Row = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30)})
    Row.Parent = parent

    local RowIcon
    if iconName then
        RowIcon = Icon(Row, iconName, UDim2.fromOffset(15, 15), state and ACCENT or COLOR.Muted, UDim2.new(0, 0, 0.5, 0), Vector2.new(0, 0.5))
    end

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
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
        Size = UDim2.fromOffset(38, 21),
    })
    Switch.Parent = Row
    Corner(Switch, 11)

    local Knob = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(17, 17),
    })
    Knob.Parent = Switch
    Corner(Knob, 9)

    local function applyVisual()
        Tween(Switch, {BackgroundColor3 = state and ACCENT or COLOR.Border}, EASE)
        Tween(Knob, {Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)}, EASE)
        if RowIcon then
            if RowIcon:IsA("ImageLabel") then
                Tween(RowIcon, {ImageColor3 = state and ACCENT or COLOR.Muted}, EASE)
            else
                Tween(RowIcon, {TextColor3 = state and ACCENT or COLOR.Muted}, EASE)
            end
        end
    end

    Switch.MouseButton1Click:Connect(function()
        state = not state
        applyVisual()
        if callback then task.spawn(callback, state) end
    end)

    return {
        Set = function(_, value) state = value; applyVisual() end,
        Get = function() return state end,
    }
end

function RocketUI:Slider(parent, text, min, max, default, callback)
    min, max = min or 0, max or 100
    local value = math.clamp(default or min, min, max)

    local Row = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38)})
    Row.Parent = parent

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -50, 0, 16),
        Parent = Row,
    })

    local ValueLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
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
        Size = UDim2.new(1, 0, 0, 5),
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
        Size = UDim2.fromOffset(13, 13),
        ZIndex = 2,
    })
    Knob.Parent = Track
    Corner(Knob, 7)

    local dragging = false

    local function update(inputPos)
        local rel = math.clamp((inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, 0, 0.5, 0)
        ValueLabel.Text = tostring(value)
        if callback then task.spawn(callback, value) end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Set = function(_, v)
            v = math.clamp(v, min, max)
            value = v
            local r = ratio(v)
            Tween(Fill, {Size = UDim2.new(r, 0, 1, 0)}, EASE)
            Tween(Knob, {Position = UDim2.new(r, 0, 0.5, 0)}, EASE)
            ValueLabel.Text = tostring(v)
        end,
        Get = function() return value end,
    }
end

function RocketUI:Button(parent, text, iconName, callback, primary)
    local Btn = New("TextButton", {
        BackgroundColor3 = primary and ACCENT or COLOR.Card,
        BackgroundTransparency = primary and 0 or 0.15,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
    })
    Btn.Parent = parent
    Corner(Btn, 9)
    if not primary then Stroke(Btn, COLOR.Border, 0.3) end

    if iconName then
        Icon(Btn, iconName, UDim2.fromOffset(14, 14), primary and COLOR.Bg or COLOR.SubText, UDim2.new(0, 12, 0.5, 0), Vector2.new(0, 0.5))
    end

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextColor3 = primary and COLOR.Bg or COLOR.Text,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.fromOffset(iconName and 34 or 12, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Btn,
    })

    Btn.MouseEnter:Connect(function()
        Tween(Btn, {BackgroundTransparency = primary and 0.12 or 0}, EASE)
    end)
    Btn.MouseLeave:Connect(function()
        Tween(Btn, {BackgroundTransparency = primary and 0 or 0.15}, EASE)
    end)
    Btn.MouseButton1Click:Connect(function()
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
    })
    Row.Parent = parent

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 16),
        Parent = Row,
    })

    local Head = New("TextButton", {
        BackgroundColor3 = COLOR.Bg,
        BackgroundTransparency = 0.2,
        AutoButtonColor = false,
        Text = "",
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, 0, 0, 32),
    })
    Head.Parent = Row
    Corner(Head, 8)
    local headStroke = Stroke(Head, COLOR.Border, 0.3)

    local SelectedLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = tostring(selected),
        TextSize = 13,
        TextColor3 = COLOR.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -36, 1, 0),
    })
    SelectedLabel.Parent = Head

    local Chevron = Icon(Head, "chevron-down", UDim2.fromOffset(14, 14), COLOR.Muted, UDim2.new(1, -12, 0.5, 0), Vector2.new(1, 0.5))

    local ListFrame = New("Frame", {
        BackgroundColor3 = COLOR.Bg,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 58),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 5,
    })
    ListFrame.Parent = Row
    Corner(ListFrame, 8)
    Stroke(ListFrame, COLOR.Border, 0.3)

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ListFrame

    for i, opt in ipairs(options) do
        local OptBtn = New("TextButton", {
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
            Font = Enum.Font.Gotham,
            Text = tostring(opt),
            TextSize = 12,
            TextColor3 = COLOR.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -20, 1, 0),
            ZIndex = 6,
            Parent = OptBtn,
        })

        OptBtn.MouseEnter:Connect(function() Tween(OptBtn, {BackgroundTransparency = 0.9}, EASE) end)
        OptBtn.MouseLeave:Connect(function() Tween(OptBtn, {BackgroundTransparency = 1}, EASE) end)
        OptBtn.BackgroundColor3 = ACCENT

        OptBtn.MouseButton1Click:Connect(function()
            selected = opt
            SelectedLabel.Text = tostring(opt)
            open = false
            Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, EASE)
            Tween(Chevron, {Rotation = 0}, EASE)
            task.delay(0.2, function() ListFrame.Visible = false end)
            if callback then task.spawn(callback, opt) end
        end)
    end

    Head.MouseButton1Click:Connect(function()
        open = not open
        ListFrame.Visible = true
        local targetH = open and math.min(#options * 30, 150) or 0
        Tween(ListFrame, {Size = UDim2.new(1, 0, 0, targetH)}, EASE)
        Tween(Chevron, {Rotation = open and 180 or 0}, EASE)
        if not open then
            task.delay(0.22, function()
                if not open then ListFrame.Visible = false end
            end)
        end
    end)

    return {Get = function() return selected end}
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

RocketUI.SectionCard = Card

-- ============================================================
-- ROW de N cards lado a lado (responsivo simples: empilha se faltar espaço)
-- ============================================================

local function Row3(parent, order)
    local R = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 78),
        LayoutOrder = order,
    })
    R.Parent = parent

    local L = Instance.new("UIListLayout")
    L.FillDirection = Enum.FillDirection.Horizontal
    L.Padding = UDim.new(0, 10)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    L.Parent = R

    return R
end

-- ============================================================
-- PÁGINAS DE EXEMPLO (estilo dashboard da referência)
-- ============================================================

local HomePage = AddTab("Dashboard", "layout-dashboard")
do
    local StatsRow = Row3(HomePage, 1)
    local c1 = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0.333, -7, 1, 0), Parent = StatsRow})
    local c2 = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0.333, -7, 1, 0), Parent = StatsRow})
    local c3 = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0.333, -6, 1, 0), Parent = StatsRow})

    RocketUI:StatCard(c1, "Leads", "129", "8.0%", "up")
    RocketUI:StatCard(c2, "Conversion Rate", "24%", "2.0%", "up")
    RocketUI:StatCard(c3, "Ping", "—", "4.0%", "down")

    RocketUI:LineChart(HomePage, {12, 18, 15, 22, 19, 25, 21, 28, 24, 30, 27, 26}, 2)

    local Quick = Card(HomePage, 3)
    Pad(Quick, 14, 12, 14, 12)
    local ql = Instance.new("UIListLayout")
    ql.SortOrder = Enum.SortOrder.LayoutOrder
    ql.Padding = UDim.new(0, 10)
    ql.Parent = Quick

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "AÇÕES RÁPIDAS",
        TextSize = 11,
        TextColor3 = ACCENT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 14),
        Parent = Quick,
    })

    RocketUI:Button(Quick, "Recarregar Ícones", "refresh-cw", function()
        LoadIcons()
        Toast("Ícones recarregados", "check", COLOR.Green)
    end)
end

local CombatPage = AddTab("Combat", "sword")
do
    local Aim = Card(CombatPage, 1)
    Pad(Aim, 14, 12, 14, 12)
    local l1 = Instance.new("UIListLayout"); l1.Padding = UDim.new(0, 10); l1.Parent = Aim
    New("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "AIMBOT", TextSize = 11, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1,0,0,14), Parent = Aim})

    RocketUI:Toggle(Aim, "Ativar Aimbot", false, "crosshair", function(state)
        Toast(state and "Aimbot ativado" or "Aimbot desativado", "crosshair")
    end)
    RocketUI:Slider(Aim, "FOV", 10, 200, 90)
    RocketUI:Dropdown(Aim, "Parte do corpo", {"Head", "Torso", "HumanoidRootPart"}, "Head")

    local Combat = Card(CombatPage, 2)
    Pad(Combat, 14, 12, 14, 12)
    local l2 = Instance.new("UIListLayout"); l2.Padding = UDim.new(0, 10); l2.Parent = Combat
    New("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "COMBATE GERAL", TextSize = 11, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1,0,0,14), Parent = Combat})
    RocketUI:Toggle(Combat, "Auto Parry", false, "shield")
    RocketUI:Toggle(Combat, "Kill Aura", false, "flame")
end

local VisualsPage = AddTab("Visuals", "eye")
do
    local Esp = Card(VisualsPage, 1)
    Pad(Esp, 14, 12, 14, 12)
    local l1 = Instance.new("UIListLayout"); l1.Padding = UDim.new(0, 10); l1.Parent = Esp
    New("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "ESP", TextSize = 11, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1,0,0,14), Parent = Esp})
    RocketUI:Toggle(Esp, "Players ESP", false, "users")
    RocketUI:Toggle(Esp, "Chams", false, "sparkles")
    RocketUI:Slider(Esp, "Transparência", 0, 100, 50)
end

local SettingsPage = AddTab("Settings", "settings")
do
    local UiSettings = Card(SettingsPage, 1)
    Pad(UiSettings, 14, 12, 14, 12)
    local l1 = Instance.new("UIListLayout"); l1.Padding = UDim.new(0, 10); l1.Parent = UiSettings
    New("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "INTERFACE", TextSize = 11, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1,0,0,14), Parent = UiSettings})

    RocketUI:Dropdown(UiSettings, "Tema de Destaque", {"Laranja", "Vermelho", "Violeta"}, "Laranja", function(v)
        local map = {Laranja = COLOR.Orange, Vermelho = COLOR.Red, Violeta = COLOR.Violet}
        ACCENT = map[v]
        for _, data in pairs(RocketUI.Tabs) do
            if data.Page.Visible then
                if data.Icon:IsA("ImageLabel") then data.Icon.ImageColor3 = ACCENT
                else data.Icon.TextColor3 = ACCENT end
            end
        end
        Toast("Tema alterado para " .. v, "palette", ACCENT)
    end)

    local About = Card(SettingsPage, 2)
    Pad(About, 14, 12, 14, 12)
    local l2 = Instance.new("UIListLayout"); l2.Padding = UDim.new(0, 6); l2.Parent = About
    New("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "SOBRE", TextSize = 11, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1,0,0,14), Parent = About})
    RocketUI:Label(About, "RocketUI Hub v3 — desenvolvido por CoiledTom.", true)
    RocketUI:Label(About, "Estilo inspirado em dashboards dark modernos.", true)
end

-- ============================================================
-- INIT
-- ============================================================

SelectTab("Dashboard")

print("[RocketUI] Hub v3 (dashboard style) carregado!")

return RocketUI
