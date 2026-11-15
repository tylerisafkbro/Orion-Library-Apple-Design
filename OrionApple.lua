-- ================================================================
--  ORION LIBRARY — APPLE LIQUID GLASS (DISCORD CSS EDITION)
--  Drop-in replacement for OrionLib source.
-- ================================================================

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = game:GetService("Players").LocalPlayer
local Mouse            = LocalPlayer:GetMouse()
local HttpService      = game:GetService("HttpService")

-- ── Apple Liquid Glass Design Tokens ───────────────────────────
local A = {
	-- Hintergrund (Wallpaper)
	BG        = Color3.fromRGB(9, 10, 15),      -- Sehr dunkles Blau/Schwarz
	Panel     = Color3.fromRGB(24, 26, 32),     -- Glass Panel Base (etwas heller)
	Elevated  = Color3.fromRGB(34, 37, 46),     -- Menüs & Popups
	Stroke    = Color3.fromRGB(255, 255, 255),  -- Weiße Lichtkante
	Divider   = Color3.fromRGB(45, 48, 58),     -- Trennlinien

	-- Text
	Text      = Color3.fromRGB(242, 242, 250),  
	TextDark  = Color3.fromRGB(140, 142, 160),  

	-- Akzente
	Blue      = Color3.fromRGB(10, 132, 255),   -- Apple Blau
	BlueGlow  = Color3.fromRGB(10, 132, 255),   
	Green     = Color3.fromRGB(48, 209, 88),    
	Red       = Color3.fromRGB(255, 69, 58),    
}

local OrionLib = {
	Elements    = {},
	ThemeObjects= {},
	Connections = {},
	Flags       = {},
	Themes = {
		Default = {
			Main     = A.BG,
			Second   = A.Panel,
			Stroke   = A.Stroke,
			Divider  = A.Divider,
			Text     = A.Text,
			TextDark = A.TextDark,
		}
	},
	SelectedTheme = "Default",
	Folder  = nil,
	SaveCfg = false,
}

-- ── Icons ────────────────────────────────────────────────────────
local Icons = {}
pcall(function()
	Icons = HttpService:JSONDecode(
		game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")
	).icons
end)

local function GetIcon(n) return Icons[n] or nil end

-- ── ScreenGui ───────────────────────────────────────────────────
local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn then syn.protect_gui(Orion); Orion.Parent = game.CoreGui
else Orion.Parent = gethui and gethui() or game.CoreGui end

local _hub = gethui and gethui() or game.CoreGui
for _, v in ipairs(_hub:GetChildren()) do
	if v.Name == "Orion" and v ~= Orion then v:Destroy() end
end

function OrionLib:IsRunning()
	return Orion.Parent == (gethui and gethui() or game:GetService("CoreGui"))
end

local function AddConnection(sig, fn)
	if not OrionLib:IsRunning() then return end
	local c = sig:Connect(fn)
	table.insert(OrionLib.Connections, c)
	return c
end

task.spawn(function()
	while OrionLib:IsRunning() do wait() end
	for _, c in next, OrionLib.Connections do c:Disconnect() end
end)

-- ── Drag ────────────────────────────────────────────────────────
local function AddDraggingFunctionality(DragPoint, Main)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos
		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Dragging = true; MousePos = Input.Position; FramePos = Main.Position
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
				end)
			end
		end)
		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement then DragInput = Input end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging then
				local D = Input.Position - MousePos
				-- Apple Spring Animation beim Draggen
				TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + D.X, FramePos.Y.Scale, FramePos.Y.Offset + D.Y)
				}):Play()
			end
		end)
	end)
end

-- ── Helpers ──────────────────────────────────────────────────────
local function Create(Name, Props, Children)
	local o = Instance.new(Name)
	for k,v in next, Props or {} do o[k]=v end
	for _,v in next, Children or {} do v.Parent=o end
	return o
end

local function CreateElement(name, fn) OrionLib.Elements[name] = fn end
local function MakeElement(name, ...) return OrionLib.Elements[name](...) end
local function SetProps(e, p) table.foreach(p, function(k,v) e[k]=v end); return e end
local function SetChildren(e, c) table.foreach(c, function(_,v) v.Parent=e end); return e end

local function Round(n, f)
	local r = math.floor(n/f + math.sign(n)*0.5)*f
	if r < 0 then r = r+f end; return r
end

local function ReturnProperty(o)
	if o:IsA("Frame") or o:IsA("TextButton")  then return "BackgroundColor3" end
	if o:IsA("ScrollingFrame")                 then return "ScrollBarImageColor3" end
	if o:IsA("UIStroke")                       then return "Color" end
	if o:IsA("TextLabel") or o:IsA("TextBox") then return "TextColor3" end
	if o:IsA("ImageLabel") or o:IsA("ImageButton") then return "ImageColor3" end
end

local function AddThemeObject(obj, t)
	OrionLib.ThemeObjects[t] = OrionLib.ThemeObjects[t] or {}
	table.insert(OrionLib.ThemeObjects[t], obj)
	obj[ReturnProperty(obj)] = OrionLib.Themes[OrionLib.SelectedTheme][t]
	return obj
end

local function PackColor(c)   return {R=c.R*255,G=c.G*255,B=c.B*255} end
local function UnpackColor(c) return Color3.fromRGB(c.R,c.G,c.B) end

local function LoadCfg(cfg)
	local data = HttpService:JSONDecode(cfg)
	table.foreach(data, function(a,b)
		if OrionLib.Flags[a] then
			spawn(function()
				if OrionLib.Flags[a].Type == "Colorpicker" then OrionLib.Flags[a]:Set(UnpackColor(b))
				else OrionLib.Flags[a]:Set(b) end
			end)
		end
	end)
end

local function SaveCfg(name)
	local data = {}
	for i,v in pairs(OrionLib.Flags) do
		if v.Save then data[i] = (v.Type == "Colorpicker") and PackColor(v.Value) or v.Value end
	end
	if writefile then pcall(function() writefile(OrionLib.Folder.."/"..name..".txt", HttpService:JSONEncode(data)) end) end
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1,Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local BlacklistedKeys  = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function CheckKey(t, k)
	for _,v in next, t do if v==k then return true end end
end

-- ════════════════════════════════════════════════════════════════
--  ELEMENT FACTORIES — Liquid Glass edition
-- ════════════════════════════════════════════════════════════════

-- Extrem runde Ecken für Apple-Feel
CreateElement("Corner", function(scale, offset)
	return Create("UICorner", {CornerRadius = UDim.new(scale or 0, offset or 16)})
end)

-- Weiße Lichtkante (innen) mit Transparenz für das "Glas"-Gefühl
CreateElement("Stroke", function(color, thickness)
	return Create("UIStroke", {
		Color        = color or A.Stroke,
		Thickness    = thickness or 1,
		Transparency = 0.82, -- Sehr subtil, wie im CSS
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end)

CreateElement("List", function(scale, offset)
	return Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(scale or 0, offset or 0)})
end)

CreateElement("Padding", function(b,l,r,t)
	return Create("UIPadding", {
		PaddingBottom = UDim.new(0, b or 4), PaddingLeft = UDim.new(0, l or 4),
		PaddingRight  = UDim.new(0, r or 4), PaddingTop  = UDim.new(0, t or 4),
	})
end)

CreateElement("TFrame", function() return Create("Frame", {BackgroundTransparency=1}) end)
CreateElement("Frame", function(color) return Create("Frame", {BackgroundColor3=color or A.Panel, BorderSizePixel=0}) end)

CreateElement("RoundFrame", function(color, scale, offset)
	return Create("Frame", {BackgroundColor3 = color or A.Panel, BorderSizePixel = 0}, {Create("UICorner", {CornerRadius=UDim.new(scale or 0, offset or 16)})})
end)

CreateElement("Button", function() return Create("TextButton", {Text="",AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0}) end)

CreateElement("ScrollFrame", function(color, width)
	return Create("ScrollingFrame", {
		BackgroundTransparency = 1, MidImage = "rbxassetid://7445543667", BottomImage = "rbxassetid://7445543667", TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = color or A.Divider, BorderSizePixel = 0, ScrollBarThickness = width or 3, CanvasSize = UDim2.new(0,0,0,0),
	})
end)

CreateElement("Image", function(id)
	local img = Create("ImageLabel", {Image=id, BackgroundTransparency=1})
	if GetIcon(id) then img.Image = GetIcon(id) end
	return img
end)

CreateElement("Label", function(text, size, transparency)
	return Create("TextLabel", {
		Text = text or "", TextColor3 = A.Text, TextTransparency = transparency or 0,
		TextSize = size or 15, Font = Enum.Font.GothamBold, RichText = true,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	})
end)

-- ── Notification (mit Apple Bounce) ─────────────────────────────
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8)})
}), {Position = UDim2.new(1,-20,1,-20), Size = UDim2.new(0,310,1,-20), AnchorPoint = Vector2.new(1,1), Parent = Orion})

function OrionLib:MakeNotification(cfg)
	spawn(function()
		cfg.Name = cfg.Name or "Notification"; cfg.Content = cfg.Content or ""
		cfg.Image = cfg.Image or "rbxassetid://4384403532"; cfg.Time = cfg.Time or 15

		local np = SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Parent=NotificationHolder})

		local nf = SetChildren(SetProps(Create("Frame", {BackgroundColor3 = A.Elevated, BorderSizePixel = 0}, {Create("UICorner",{CornerRadius=UDim.new(0,16)})}), {
			Parent = np, Size = UDim2.new(1,0,0,0), Position = UDim2.new(1,-50,0,0), BackgroundTransparency = 0.15, AutomaticSize = Enum.AutomaticSize.Y,
		}), {
			Create("UIStroke",{Color=A.Stroke, Thickness=1, Transparency=0.85}),
			MakeElement("Padding", 12,14,14,12),
			SetProps(MakeElement("Image", cfg.Image), {Size=UDim2.new(0,20,0,20), ImageColor3=A.Text, Name="Icon"}),
			SetProps(MakeElement("Label", cfg.Name, 15), {Size=UDim2.new(1,-30,0,20), Position=UDim2.new(0,30,0,0), Font=Enum.Font.GothamBold, Name="Title"}),
			SetProps(MakeElement("Label", cfg.Content, 13), {Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,26), Name="Content", AutomaticSize=Enum.AutomaticSize.Y, TextColor3=A.TextDark, TextWrapped=true}),
		})

		-- Bounce In
		TweenService:Create(nf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)}):Play()
		wait(cfg.Time - 0.88)
		
		TweenService:Create(nf.Icon, TweenInfo.new(0.4,Enum.EasingStyle.Quint),{ImageTransparency=1}):Play()
		TweenService:Create(nf, TweenInfo.new(0.8,Enum.EasingStyle.Quint),{BackgroundTransparency=0.8}):Play()
		wait(0.3)
		TweenService:Create(nf.UIStroke, TweenInfo.new(0.6,Enum.EasingStyle.Quint),{Transparency=1}):Play()
		TweenService:Create(nf.Title, TweenInfo.new(0.6,Enum.EasingStyle.Quint),{TextTransparency=0.5}):Play()
		TweenService:Create(nf.Content, TweenInfo.new(0.6,Enum.EasingStyle.Quint),{TextTransparency=0.6}):Play()
		wait(0.05)
		nf:TweenPosition(UDim2.new(1,20,0,0),"In","Quint",0.8,true)
		wait(1.35)
		nf:Destroy()
	end)
end

-- ════════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════════
function OrionLib:MakeWindow(wc)
	local FirstTab = true
	local Minimized, UIHidden = false, false

	wc = wc or {}
	wc.Name           = wc.Name           or "Orion"
	wc.ConfigFolder   = wc.ConfigFolder   or wc.Name
	wc.SaveConfig     = wc.SaveConfig     or false
	wc.HidePremium    = wc.HidePremium    or false
	wc.IntroEnabled   = (wc.IntroEnabled ~= nil) and wc.IntroEnabled or true
	wc.IntroText      = wc.IntroText      or wc.Name
	wc.CloseCallback  = wc.CloseCallback  or function() end
	wc.ShowIcon       = wc.ShowIcon       or false
	wc.Icon           = wc.Icon           or "rbxassetid://8834748103"
	wc.IntroIcon      = wc.IntroIcon      or "rbxassetid://8834748103"
	OrionLib.Folder   = wc.ConfigFolder
	OrionLib.SaveCfg  = wc.SaveConfig

	if wc.SaveConfig and isfolder then
		pcall(function() if not isfolder(wc.ConfigFolder) then makefolder(wc.ConfigFolder) end end)
	end

	-- ── Tab sidebar scroll ────────────────────────────────────
	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", A.Stroke, 3), {
		Size = UDim2.new(1,0,1,-54),
	}), {
		MakeElement("List"),
		MakeElement("Padding", 8,0,0,8),
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0,0,0,TabHolder.UIListLayout.AbsoluteContentSize.Y+16)
	end)

	-- ── Top Bar Buttons (Pill Design) ─────────────────────────
	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0)}), {
		AddThemeObject(SetProps(MakeElement("Image","rbxassetid://7072725342"),{Position=UDim2.new(0,9,0,6), Size=UDim2.new(0,18,0,18)}), "Text")
	})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"),{Size=UDim2.new(0.5,0,1,0)}), {
		AddThemeObject(SetProps(MakeElement("Image","rbxassetid://7072719338"),{Position=UDim2.new(0,9,0,6), Size=UDim2.new(0,18,0,18), Name="Ico"}), "Text")
	})

	local DragPoint = SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,54)})

	-- ── Left sidebar panel ────────────────────────────────────
	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", A.Panel, 0, 20), {
		Size=UDim2.new(0,160,1,-54), Position=UDim2.new(0,0,0,54), BackgroundTransparency=0.15
	}), {
		AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,20), BackgroundTransparency=1}), "Second"),
		AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-20,0,0), BackgroundTransparency=1}), "Second"),
		AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0)}), "Stroke"),
		TabHolder,
		-- bottom user card
		SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,54),Position=UDim2.new(0,0,1,-54)}), {
			AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1), BackgroundTransparency=0.8}), "Stroke"),
			AddThemeObject(SetChildren(SetProps(MakeElement("Frame"),{AnchorPoint=Vector2.new(0,.5), Size=UDim2.new(0,34,0,34), Position=UDim2.new(0,10,.5,0), BackgroundTransparency=1}), {
				SetProps(MakeElement("Image","https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=420&height=420&format=png"),{Size=UDim2.new(1,0,1,0)}),
				AddThemeObject(SetProps(MakeElement("Image","rbxassetid://4031889928"),{Size=UDim2.new(1,0,1,0)}), "Second"),
				MakeElement("Corner",1),
			}), "Divider"),
			SetChildren(SetProps(MakeElement("TFrame"),{AnchorPoint=Vector2.new(0,.5),Size=UDim2.new(0,34,0,34),Position=UDim2.new(0,10,.5,0)}),{
				AddThemeObject(MakeElement("Stroke"), "Stroke"), MakeElement("Corner",1)
			}),
			AddThemeObject(SetProps(MakeElement("Label",LocalPlayer.DisplayName, 13),{
				Size=UDim2.new(1,-58,0,13), Position=UDim2.new(0,52,0,13), Font=Enum.Font.GothamBold, ClipsDescendants=true,
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label","",12),{Size=UDim2.new(1,-58,0,12), Position=UDim2.new(0,52,1,-26), Visible=not wc.HidePremium}), "TextDark"),
		}),
	}), "Second")

	local WindowName = AddThemeObject(SetProps(MakeElement("Label",wc.Name,14),{
		Size=UDim2.new(1,-30,2,0), Position=UDim2.new(0,22,0,-26), Font=Enum.Font.GothamBlack, TextSize=20,
	}), "Text")

	local TopBarLine = AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundTransparency=0.8}), "Stroke")

	-- ── Main window frame ──────────────────────────────────────
	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", A.BG, 0, 20), {
		Parent = Orion, Position = UDim2.new(.5,-320,.5,-180), Size = UDim2.new(0,640,0,360), ClipsDescendants = true, BackgroundTransparency = 0.05
	}), {
		Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.82}),
		SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,54),Name="TopBar"}), {
			WindowName, TopBarLine,
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Elevated,0,12),{
				Size=UDim2.new(0,72,0,30), Position=UDim2.new(1,-92,0,12), BackgroundTransparency=0.15
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(0,1,1,0),Position=UDim2.new(.5,0,0,0)}), "Stroke"),
				CloseBtn, MinimizeBtn,
			}), "Second"),
		}),
		DragPoint,
		WindowStuff,
	}), "Main")

	AddDraggingFunctionality(DragPoint, MainWindow)

	-- Buttons Logik
	AddConnection(CloseBtn.MouseButton1Up, function()
		MainWindow.Visible = false; UIHidden = true
		OrionLib:MakeNotification({Name="Hidden",Content="Press RightShift to reopen",Time=4})
		wc.CloseCallback()
	end)
	AddConnection(UserInputService.InputBegan, function(i)
		if i.KeyCode == Enum.KeyCode.RightShift and UIHidden then MainWindow.Visible = true end
	end)

	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Minimized then
			TweenService:Create(MainWindow,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,640,0,360)}):Play()
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
			wait(.02); MainWindow.ClipsDescendants=false; WindowStuff.Visible=true; TopBarLine.Visible=true
		else
			MainWindow.ClipsDescendants=true; TopBarLine.Visible=false
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
			TweenService:Create(MainWindow,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,WindowName.TextBounds.X+150,0,54)}):Play()
			wait(.1); WindowStuff.Visible=false
		end
		Minimized = not Minimized
	end)

	-- ── Intro sequence ─────────────────────────────────────────
	local function LoadSequence()
		MainWindow.Visible = false
		local logo = SetProps(MakeElement("Image",wc.IntroIcon),{Parent=Orion, AnchorPoint=Vector2.new(.5,.5), Position=UDim2.new(.5,0,.4,0), Size=UDim2.new(0,30,0,30), ImageColor3=Color3.new(1,1,1), ImageTransparency=1})
		local txt = SetProps(MakeElement("Label",wc.IntroText,14),{Parent=Orion, Size=UDim2.new(1,0,1,0), AnchorPoint=Vector2.new(.5,.5), Position=UDim2.new(.5,20,.5,0), TextXAlignment=Enum.TextXAlignment.Center, Font=Enum.Font.GothamBold, TextTransparency=1})
		
		TweenService:Create(logo,TweenInfo.new(.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{ImageTransparency=0,Position=UDim2.new(.5,0,.5,0)}):Play()
		wait(.8)
		TweenService:Create(logo,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(.5,-(txt.TextBounds.X/2),.5,0)}):Play()
		wait(.3)
		TweenService:Create(txt,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
		wait(1.8)
		TweenService:Create(txt,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=1}):Play()
		MainWindow.Visible=true; logo:Destroy(); txt:Destroy()
	end
	if wc.IntroEnabled then LoadSequence() end

	-- ════════════════════════════════════════════════════════════
	--  TAB FUNCTION
	-- ════════════════════════════════════════════════════════════
	local TabFunction = {}

	function TabFunction:MakeTab(tc)
		tc = tc or {}
		tc.Name       = tc.Name       or "Tab"
		tc.Icon       = tc.Icon       or ""
		tc.PremiumOnly= tc.PremiumOnly or false

		local TabFrame = SetChildren(SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,0,36), Parent=TabHolder}), {
			AddThemeObject(SetProps(MakeElement("Image",tc.Icon),{AnchorPoint=Vector2.new(0,.5), Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,10,.5,0), ImageTransparency=0.5, Name="Ico"}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label",tc.Name,14),{Size=UDim2.new(1,-38,1,0), Position=UDim2.new(0,36,0,0), Font=Enum.Font.GothamSemibold, TextTransparency=0.5, Name="Title"}), "Text"),
		})

		if GetIcon(tc.Icon) then TabFrame.Ico.Image = GetIcon(tc.Icon) end

		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame",A.Stroke,4),{
			Size=UDim2.new(1,-160,1,-54), Position=UDim2.new(0,160,0,54), Parent=MainWindow, Visible=false, Name="ItemContainer",
		}), {MakeElement("List",0,10), MakeElement("Padding",14,10,10,14)}), "Divider")

		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0,0,0,Container.UIListLayout.AbsoluteContentSize.Y+30)
		end)

		if FirstTab then
			FirstTab = false; TabFrame.Ico.ImageTransparency = 0; TabFrame.Title.TextTransparency = 0
			TabFrame.Title.Font = Enum.Font.GothamBlack; Container.Visible = true
		end

		local ActivePill = Create("Frame",{BackgroundColor3 = A.Blue, BorderSizePixel = 0, Size = UDim2.new(0,3,0.5,0), Position = UDim2.new(0,0,0.25,0), Visible = false},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
		ActivePill.Parent = TabFrame

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, t in next, TabHolder:GetChildren() do
				if t:IsA("TextButton") then
					t.Title.Font = Enum.Font.GothamSemibold
					TweenService:Create(t.Ico,  TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{ImageTransparency=0.5}):Play()
					TweenService:Create(t.Title,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{TextTransparency=0.5}):Play()
					if t:FindFirstChild("ActivePill") then t.ActivePill.Visible=false end
				end
			end
			for _, ic in next, MainWindow:GetChildren() do if ic.Name=="ItemContainer" then ic.Visible=false end end
			TweenService:Create(TabFrame.Ico,  TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{ImageTransparency=0}):Play()
			TweenService:Create(TabFrame.Title,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBlack; ActivePill.Visible = true; Container.Visible  = true
		end)

		local function GetElements(ItemParent)
			local EF = {}

			function EF:AddLabel(text)
				local lf = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,34), BackgroundTransparency=0.15, Parent=ItemParent}), {
					AddThemeObject(SetProps(MakeElement("Label",text,14),{Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamBold, Name="Content"}), "Text"),
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}),
				}), "Second")
				local lf2 = {}; function lf2:Set(t) lf.Content.Text=t end; return lf2
			end

			function EF:AddParagraph(text, content)
				text=text or "Text"; content=content or ""
				local pf = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,34), BackgroundTransparency=0.15, Parent=ItemParent}), {
					AddThemeObject(SetProps(MakeElement("Label",text,14),{Size=UDim2.new(1,-14,0,14), Position=UDim2.new(0,14,0,10), Font=Enum.Font.GothamBold, Name="Title"}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label","",13),{Size=UDim2.new(1,-28,0,0), Position=UDim2.new(0,14,0,28), Name="Content", TextWrapped=true}), "TextDark"),
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}),
				}), "Second")
				AddConnection(pf.Content:GetPropertyChangedSignal("Text"), function()
					pf.Content.Size = UDim2.new(1,-28,0,pf.Content.TextBounds.Y)
					pf.Size = UDim2.new(1,0,0,pf.Content.TextBounds.Y+38)
				end)
				pf.Content.Text = content
				local pf2={}; function pf2:Set(t) pf.Content.Text=t end; return pf2
			end

			function EF:AddButton(bc)
				bc=bc or {}; bc.Name = bc.Name or "Button"; bc.Callback = bc.Callback or function() end; bc.Icon = bc.Icon or "rbxassetid://3944703587"
				local Btn = {}; local click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
				local bf = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,38), Parent=ItemParent, BackgroundTransparency=0.15}), {
					AddThemeObject(SetProps(MakeElement("Label",bc.Name,15),{Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamBold, Name="Content"}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image",bc.Icon),{Size=UDim2.new(0,18,0,18), Position=UDim2.new(1,-30,0,10)}), "TextDark"),
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}), click,
				}), "Second")
				
				AddConnection(click.MouseEnter, function() TweenService:Create(bf,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=A.Elevated}):Play() end)
				AddConnection(click.MouseLeave, function() TweenService:Create(bf,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=A.Panel}):Play() end)
				AddConnection(click.MouseButton1Down, function() TweenService:Create(bf,TweenInfo.new(.1,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(50,52,78)}):Play() end)
				AddConnection(click.MouseButton1Up, function()
					TweenService:Create(bf,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{BackgroundColor3=A.Elevated}):Play()
					spawn(bc.Callback)
				end)
				function Btn:Set(t) bf.Content.Text=t end; return Btn
			end

			function EF:AddToggle(tc2)
				tc2=tc2 or {}; tc2.Name = tc2.Name or "Toggle"; tc2.Default = tc2.Default or false; tc2.Callback = tc2.Callback or function() end
				tc2.Color = tc2.Color or A.Blue; tc2.Flag = tc2.Flag or nil; tc2.Save = tc2.Save or false
				
				local Toggle = {Value=tc2.Default, Save=tc2.Save}; local click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
				local Track = Create("Frame",{Size=UDim2.new(0,44,0,26), Position=UDim2.new(1,-12,.5,0), AnchorPoint=Vector2.new(1,.5), BackgroundColor3=A.Divider, BorderSizePixel=0},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				local Thumb = Create("Frame",{Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,3,.5,0), AnchorPoint=Vector2.new(0,.5), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				Thumb.Parent = Track

				local tf = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,38), Parent=ItemParent, BackgroundTransparency=0.15}), {
					AddThemeObject(SetProps(MakeElement("Label",tc2.Name,15),{Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamBold, Name="Content"}), "Text"),
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}), Track, click,
				}), "Second")

				function Toggle:Set(val)
					Toggle.Value = val
					TweenService:Create(Track,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{BackgroundColor3= val and tc2.Color or A.Divider}):Play()
					TweenService:Create(Thumb,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position= val and UDim2.new(1,-23,.5,0) or UDim2.new(0,3,.5,0)}):Play()
					tc2.Callback(val)
				end
				Toggle:Set(Toggle.Value)
				AddConnection(click.MouseEnter, function() TweenService:Create(tf,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=A.Elevated}):Play() end)
				AddConnection(click.MouseLeave, function() TweenService:Create(tf,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=A.Panel}):Play() end)
				AddConnection(click.MouseButton1Up, function() SaveCfg(game.GameId); Toggle:Set(not Toggle.Value) end)
				if tc2.Flag then OrionLib.Flags[tc2.Flag]=Toggle end
				return Toggle
			end

			function EF:AddSlider(sc)
				sc=sc or {}; sc.Name = sc.Name or "Slider"; sc.Min = sc.Min or 0; sc.Max = sc.Max or 100; sc.Increment = sc.Increment or 1
				sc.Default = sc.Default or 50; sc.Callback = sc.Callback or function() end; sc.ValueName = sc.ValueName or ""; sc.Color = sc.Color or A.Blue
				sc.Flag = sc.Flag or nil; sc.Save = sc.Save or false

				local Slider = {Value=sc.Default, Save=sc.Save}; local Dragging = false
				local Fill = Create("Frame",{Size=UDim2.new(0,0,1,0), BackgroundColor3=sc.Color, BorderSizePixel=0, ClipsDescendants=true},{Create("UICorner",{CornerRadius=UDim.new(1,0)}), SetProps(MakeElement("Label","val",12),{Size=UDim2.new(1,-10,0,12), Position=UDim2.new(0,10,0,7), Font=Enum.Font.GothamBold, Name="Value"})})
				local Track = SetChildren(Create("Frame",{Size=UDim2.new(1,-24,0,28), Position=UDim2.new(0,12,0,34), BackgroundColor3=A.Divider, BorderSizePixel=0},{Create("UICorner",{CornerRadius=UDim.new(1,0)})}),{
					SetProps(MakeElement("Label","val",12),{Size=UDim2.new(1,-10,0,12), Position=UDim2.new(0,10,0,7), Font=Enum.Font.GothamBold, Name="Value", TextTransparency=0.6}), Fill,
				})

				local sf = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,74), Parent=ItemParent, BackgroundTransparency=0.15}), {
					AddThemeObject(SetProps(MakeElement("Label",sc.Name,15),{Size=UDim2.new(1,-14,0,14), Position=UDim2.new(0,14,0,10), Font=Enum.Font.GothamBold, Name="Content"}), "Text"),
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}), Track,
				}), "Second")

				Track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Dragging=true end end)
				Track.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Dragging=false end end)
				UserInputService.InputChanged:Connect(function(i)
					if Dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
						local s = math.clamp((i.Position.X-Track.AbsolutePosition.X)/Track.AbsoluteSize.X,0,1)
						Slider:Set(sc.Min+(sc.Max-sc.Min)*s); SaveCfg(game.GameId)
					end
				end)

				function Slider:Set(v)
					self.Value = math.clamp(Round(v,sc.Increment),sc.Min,sc.Max)
					TweenService:Create(Fill,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale((self.Value-sc.Min)/(sc.Max-sc.Min),1)}):Play()
					Track.Value.Text = tostring(self.Value).." "..sc.ValueName; Fill.Value.Text  = tostring(self.Value).." "..sc.ValueName
					sc.Callback(self.Value)
				end
				Slider:Set(Slider.Value)
				if sc.Flag then OrionLib.Flags[sc.Flag]=Slider end
				return Slider
			end

			function EF:AddDropdown(dc)
				dc=dc or {}; dc.Name = dc.Name or "Dropdown"; dc.Options = dc.Options or {}; dc.Default = dc.Default or ""; dc.Callback = dc.Callback or function() end
				dc.Flag = dc.Flag or nil; dc.Save = dc.Save or false

				local DD = {Value=dc.Default, Options=dc.Options, Buttons={}, Toggled=false, Type="Dropdown", Save=dc.Save}; local MaxElem = 5
				if not table.find(DD.Options, DD.Value) then DD.Value="..." end

				local DList = MakeElement("List")
				local DCont = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame",A.Stroke,3),{DList}),{Parent=ItemParent, Position=UDim2.new(0,0,0,44), Size=UDim2.new(1,0,1,-44), ClipsDescendants=true}), "Divider")
				local click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})

				local DF = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,44), Parent=ItemParent, ClipsDescendants=true, BackgroundTransparency=0.15}), {
					DCont,
					SetProps(SetChildren(MakeElement("TFrame"),{
						AddThemeObject(SetProps(MakeElement("Label",dc.Name,15),{Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamBold, Name="Content"}), "Text"),
						AddThemeObject(SetProps(MakeElement("Image","rbxassetid://7072706796"),{Size=UDim2.new(0,18,0,18), AnchorPoint=Vector2.new(0,.5), Position=UDim2.new(1,-28,.5,0), Name="Ico"}), "TextDark"),
						AddThemeObject(SetProps(MakeElement("Label","Selected",13),{Size=UDim2.new(1,-42,1,0), Font=Enum.Font.Gotham, Name="Selected", TextXAlignment=Enum.TextXAlignment.Right}), "TextDark"),
						AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), Name="Line", Visible=false, BackgroundTransparency=0.8}), "Stroke"),
						click,
					}),{Size=UDim2.new(1,0,0,44),ClipsDescendants=true,Name="F"}),
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}),
					Create("UICorner",{CornerRadius=UDim.new(0,12)}),
				}), "Second")

				AddConnection(DList:GetPropertyChangedSignal("AbsoluteContentSize"),function() DCont.CanvasSize=UDim2.new(0,0,0,DList.AbsoluteContentSize.Y) end)

				local function AddOptions(opts)
					for _,opt in pairs(opts) do
						local ob = AddThemeObject(SetProps(SetChildren(MakeElement("Button",A.Panel),{MakeElement("Corner",0,8), AddThemeObject(SetProps(MakeElement("Label",opt,13,.4),{Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-10,1,0), Name="Title"}), "Text")}),{Parent=DCont, Size=UDim2.new(1,0,0,32), BackgroundTransparency=1, ClipsDescendants=true}), "Divider")
						AddConnection(ob.MouseButton1Click, function() DD:Set(opt); SaveCfg(game.GameId) end)
						DD.Buttons[opt]=ob
					end
				end

				function DD:Refresh(opts,del)
					if del then for _,v in pairs(DD.Buttons) do v:Destroy() end; table.clear(DD.Options); table.clear(DD.Buttons) end
					DD.Options=opts; AddOptions(DD.Options)
				end

				function DD:Set(val)
					if not table.find(DD.Options,val) then
						DD.Value="..."; DF.F.Selected.Text=DD.Value
						for _,v in pairs(DD.Buttons) do TweenService:Create(v,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play(); TweenService:Create(v.Title,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0.4}):Play() end; return
					end
					DD.Value=val; DF.F.Selected.Text=val
					for _,v in pairs(DD.Buttons) do TweenService:Create(v,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play(); TweenService:Create(v.Title,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0.4}):Play() end
					TweenService:Create(DD.Buttons[val],TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
					TweenService:Create(DD.Buttons[val].Title,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
					return dc.Callback(DD.Value)
				end

				AddConnection(click.MouseButton1Click, function()
					DD.Toggled = not DD.Toggled; DF.F.Line.Visible = DD.Toggled
					TweenService:Create(DF.F.Ico,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Rotation=DD.Toggled and 180 or 0}):Play()
					local h = #DD.Options>MaxElem and MaxElem*32 or DList.AbsoluteContentSize.Y
					TweenService:Create(DF,TweenInfo.new(.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=DD.Toggled and UDim2.new(1,0,0,44+h) or UDim2.new(1,0,0,44)}):Play()
				end)

				DD:Refresh(DD.Options,false); DD:Set(DD.Value)
				if dc.Flag then OrionLib.Flags[dc.Flag]=DD end
				return DD
			end

			function EF:AddBind(bc)
				bc.Name = bc.Name or "Bind"; bc.Default = bc.Default or Enum.KeyCode.Unknown; bc.Hold = bc.Hold or false
				bc.Callback = bc.Callback or function() end; bc.Flag = bc.Flag or nil; bc.Save = bc.Save or false

				local Bind = {Binding=false, Type="Bind", Save=bc.Save}; local Holding = false
				local click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
				local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,8),{Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-12,.5,0), AnchorPoint=Vector2.new(1,.5), BackgroundTransparency=0.15}), {
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}),
					AddThemeObject(SetProps(MakeElement("Label","",13),{Size=UDim2.new(1,0,1,0), Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Center, Name="Value"}), "Text"),
				}), "Main")

				local bframe = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,38), Parent=ItemParent, BackgroundTransparency=0.15}), {
					AddThemeObject(SetProps(MakeElement("Label",bc.Name,15),{Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamBold, Name="Content"}), "Text"),
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}), BindBox, click,
				}), "Second")

				AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"),function() TweenService:Create(BindBox,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,BindBox.Value.TextBounds.X+18,0,26)}):Play() end)
				AddConnection(click.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then if Bind.Binding then return end; Bind.Binding=true; BindBox.Value.Text="" end end)
				AddConnection(UserInputService.InputBegan,function(i)
					if UserInputService:GetFocusedTextBox() then return end
					if (i.KeyCode.Name==Bind.Value or i.UserInputType.Name==Bind.Value) and not Bind.Binding then
						if bc.Hold then Holding=true; bc.Callback(Holding) else bc.Callback() end
					elseif Bind.Binding then
						local k
						pcall(function() if not CheckKey(BlacklistedKeys,i.KeyCode) then k=i.KeyCode end end)
						pcall(function() if CheckKey(WhitelistedMouse,i.UserInputType) and not k then k=i.UserInputType end end)
						k=k or Bind.Value; Bind:Set(k); SaveCfg(game.GameId)
					end
				end)
				AddConnection(UserInputService.InputEnded,function(i) if (i.KeyCode.Name==Bind.Value or i.UserInputType.Name==Bind.Value) and bc.Hold and Holding then Holding=false; bc.Callback(Holding) end end)
				AddConnection(click.MouseEnter,function() TweenService:Create(bframe,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=A.Elevated}):Play() end)
				AddConnection(click.MouseLeave,function() TweenService:Create(bframe,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=A.Panel}):Play() end)

				function Bind:Set(k) Bind.Binding=false; Bind.Value=k or Bind.Value; Bind.Value=Bind.Value.Name or Bind.Value; BindBox.Value.Text=Bind.Value end
				Bind:Set(bc.Default)
				if bc.Flag then OrionLib.Flags[bc.Flag]=Bind end
				return Bind
			end

			function EF:AddTextbox(tc3)
				tc3=tc3 or {}; tc3.Name = tc3.Name or "Textbox"; tc3.Default = tc3.Default or ""; tc3.TextDisappear= tc3.TextDisappear or false; tc3.Callback = tc3.Callback or function() end
				local click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
				local TBActual = Create("TextBox",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, TextColor3=A.Text, PlaceholderColor3=A.TextDark, PlaceholderText="Input", Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Center, TextSize=14, ClearTextOnFocus=false})
				local TCont = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,8),{Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-12,.5,0), AnchorPoint=Vector2.new(1,.5), BackgroundTransparency=0.15}), {
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}), TBActual,
				}), "Main")

				local tf2 = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,38), Parent=ItemParent, BackgroundTransparency=0.15}), {
					AddThemeObject(SetProps(MakeElement("Label",tc3.Name,15),{Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamBold, Name="Content"}), "Text"),
					Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}), TCont, click,
				}), "Second")

				AddConnection(TBActual:GetPropertyChangedSignal("Text"),function() TweenService:Create(TCont,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,TBActual.TextBounds.X+18,0,26)}):Play() end)
				AddConnection(TBActual.FocusLost,function() tc3.Callback(TBActual.Text); if tc3.TextDisappear then TBActual.Text="" end end)
				TBActual.Text=tc3.Default
				AddConnection(click.MouseEnter,function() TweenService:Create(tf2,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=A.Elevated}):Play() end)
				AddConnection(click.MouseLeave,function() TweenService:Create(tf2,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=A.Panel}):Play() end)
				AddConnection(click.MouseButton1Up,function() TBActual:CaptureFocus() end)
			end

			function EF:AddColorpicker(cc)
				cc=cc or {}; cc.Name = cc.Name or "Colorpicker"; cc.Default = cc.Default or Color3.fromRGB(255,255,255); cc.Callback = cc.Callback or function() end; cc.Flag = cc.Flag or nil; cc.Save = cc.Save or false
				local ColorH2,ColorS2,ColorV2 = 1,1,1; local CP = {Value=cc.Default, Toggled=false, Type="Colorpicker", Save=cc.Save}

				local ColorSel = Create("ImageLabel",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(select(3,Color3.toHSV(CP.Value))),ScaleType=Enum.ScaleType.Fit,AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Image="http://www.roblox.com/asset/?id=4805639000"})
				local HueSel   = Create("ImageLabel",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(.5,0,1-select(1,Color3.toHSV(CP.Value))),ScaleType=Enum.ScaleType.Fit,AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Image="http://www.roblox.com/asset/?id=4805639000"})

				local ColorMap = Create("ImageLabel",{Size=UDim2.new(1,-28,1,0),Visible=false,Image="rbxassetid://4155801252"},{Create("UICorner",{CornerRadius=UDim.new(0,8)}),ColorSel})
				local HueBar   = Create("Frame",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-20,0,0),Visible=false},{Create("UIGradient",{Rotation=270,Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,4)),ColorSequenceKeypoint.new(.2,Color3.fromRGB(234,255,0)),ColorSequenceKeypoint.new(.4,Color3.fromRGB(21,255,0)),ColorSequenceKeypoint.new(.6,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(.8,Color3.fromRGB(0,17,255)),ColorSequenceKeypoint.new(.9,Color3.fromRGB(255,0,251)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,4))}}),Create("UICorner",{CornerRadius=UDim.new(0,8)}),HueSel})

				local CPCont = Create("Frame",{Position=UDim2.new(0,0,0,38),Size=UDim2.new(1,0,1,-38),BackgroundTransparency=1,ClipsDescendants=true},{HueBar,ColorMap,Create("UIPadding",{PaddingLeft=UDim.new(0,32),PaddingRight=UDim.new(0,32),PaddingBottom=UDim.new(0,10),PaddingTop=UDim.new(0,16)})})
				local click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
				local CPBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,6),{Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-12,.5,0), AnchorPoint=Vector2.new(1,.5), BackgroundTransparency=0.15}), {Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85})}), "Main")

				local CPFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",A.Panel,0,12),{Size=UDim2.new(1,0,0,38), Parent=ItemParent, BackgroundTransparency=0.15}), {
					SetProps(SetChildren(MakeElement("TFrame"),{
						AddThemeObject(SetProps(MakeElement("Label",cc.Name,15),{Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamBold, Name="Content"}), "Text"),
						CPBox, click,
						AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),Name="Line",Visible=false, BackgroundTransparency=0.8}), "Stroke"),
					}),{Size=UDim2.new(1,0,0,38),ClipsDescendants=true,Name="F"}),
					CPCont, Create("UIStroke",{Color=A.Stroke,Thickness=1,Transparency=0.85}),
				}), "Second")

				AddConnection(click.MouseButton1Click, function()
					CP.Toggled = not CP.Toggled
					TweenService:Create(CPFrame,TweenInfo.new(.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=CP.Toggled and UDim2.new(1,0,0,152) or UDim2.new(1,0,0,38)}):Play()
					ColorMap.Visible=CP.Toggled; HueBar.Visible=CP.Toggled; CPFrame.F.Line.Visible=CP.Toggled
				end)

				local function UpdateCP()
					CPBox.BackgroundColor3 = Color3.fromHSV(ColorH2,ColorS2,ColorV2)
					ColorMap.BackgroundColor3 = Color3.fromHSV(ColorH2,1,1)
					CP:Set(CPBox.BackgroundColor3); cc.Callback(CPBox.BackgroundColor3); SaveCfg(game.GameId)
				end

				ColorH2 = 1-(math.clamp(HueSel.AbsolutePosition.Y-HueBar.AbsolutePosition.Y,0,HueBar.AbsoluteSize.Y)/HueBar.AbsoluteSize.Y)
				ColorS2 = (math.clamp(ColorSel.AbsolutePosition.X-ColorMap.AbsolutePosition.X,0,ColorMap.AbsoluteSize.X)/ColorMap.AbsoluteSize.X)
				ColorV2 = 1-(math.clamp(ColorSel.AbsolutePosition.Y-ColorMap.AbsolutePosition.Y,0,ColorMap.AbsoluteSize.Y)/ColorMap.AbsoluteSize.Y)

				local ColorInput2, HueInput2
				AddConnection(ColorMap.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then if ColorInput2 then ColorInput2:Disconnect() end; ColorInput2=AddConnection(RunService.RenderStepped,function() local cx=(math.clamp(Mouse.X-ColorMap.AbsolutePosition.X,0,ColorMap.AbsoluteSize.X)/ColorMap.AbsoluteSize.X); local cy=(math.clamp(Mouse.Y-ColorMap.AbsolutePosition.Y,0,ColorMap.AbsoluteSize.Y)/ColorMap.AbsoluteSize.Y); ColorSel.Position=UDim2.new(cx,0,cy,0); ColorS2=cx; ColorV2=1-cy; UpdateCP() end) end end)
				AddConnection(ColorMap.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and ColorInput2 then ColorInput2:Disconnect() end end)
				AddConnection(HueBar.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then if HueInput2 then HueInput2:Disconnect() end; HueInput2=AddConnection(RunService.RenderStepped,function() local hy=(math.clamp(Mouse.Y-HueBar.AbsolutePosition.Y,0,HueBar.AbsoluteSize.Y)/HueBar.AbsoluteSize.Y); HueSel.Position=UDim2.new(.5,0,hy,0); ColorH2=1-hy; UpdateCP() end) end end)
				AddConnection(HueBar.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and HueInput2 then HueInput2:Disconnect() end end)

				function CP:Set(val) CP.Value=val; CPBox.BackgroundColor3=val; cc.Callback(val) end
				CP:Set(CP.Value)
				if cc.Flag then OrionLib.Flags[cc.Flag]=CP end
				return CP
			end

			return EF
		end

		local ElementFunction2 = {}
		function ElementFunction2:AddSection(sc2)
			sc2=sc2 or {}; sc2.Name = sc2.Name or "Section"
			local sf3 = SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,30), Parent=Container}), {
				AddThemeObject(SetProps(MakeElement("Label",sc2.Name,13),{Size=UDim2.new(1,-12,0,16), Position=UDim2.new(0,0,0,4), Font=Enum.Font.GothamSemibold}), "TextDark"),
				SetChildren(SetProps(MakeElement("TFrame"),{AnchorPoint=Vector2.new(0,0), Size=UDim2.new(1,0,1,-28), Position=UDim2.new(0,0,0,26), Name="Holder"}), {MakeElement("List",0,10)}),
			})
			AddConnection(sf3.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
				sf3.Size=UDim2.new(1,0,0,sf3.Holder.UIListLayout.AbsoluteContentSize.Y+34); sf3.Holder.Size=UDim2.new(1,0,0,sf3.Holder.UIListLayout.AbsoluteContentSize.Y)
			end)
			local sf3Fn={}; for i,v in next, GetElements(sf3.Holder) do sf3Fn[i]=v end; return sf3Fn
		end

		for i,v in next, GetElements(Container) do ElementFunction2[i]=v end

		if tc.PremiumOnly then
			for i in next, ElementFunction2 do ElementFunction2[i]=function() end end
			Container:FindFirstChild("UIListLayout"):Destroy(); Container:FindFirstChild("UIPadding"):Destroy()
			SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,1,0),Parent=Container}),{
				AddThemeObject(SetProps(MakeElement("Image","rbxassetid://3610239960"),{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,14,0,14),ImageTransparency=0.4}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label","Unauthorised",14),{Size=UDim2.new(1,-38,0,14),Position=UDim2.new(0,38,0,16),TextTransparency=0.4}), "Text"),
			})
		end
		return ElementFunction2
	end

	return TabFunction
end

function OrionLib:Destroy() Orion:Destroy() end

return OrionLib
