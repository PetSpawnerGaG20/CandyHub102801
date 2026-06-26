-- ACE register-limit fixed build: top-level locals converted to script globals to avoid executor 200-local-register errors.
print("[ACE PC DIRECT BUILD] starting")
repeat task.wait() until game:IsLoaded()
Players,RunService,UIS,TS,Lighting,HS,SoundService = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService"),game:GetService("Lighting"),game:GetService("HttpService"),game:GetService("SoundService")
LP = Players.LocalPlayer

-- ============================================================
-- HIGH PING WARNING - added from message (70)
-- Shows a warning banner when ping is too high for duels.
-- ============================================================
do
    local PING_THRESHOLD  = 120
    local CHECK_INTERVAL  = 1.0
    local DISMISS_AFTER   = 6.0

    -- Parent ScreenGui
    local pgPing = LP:WaitForChild("PlayerGui")
    local oldGui = pgPing:FindFirstChild("AdaptPingWarning")
    if oldGui then oldGui:Destroy() end

    local pingGui = Instance.new("ScreenGui")
    pingGui.Name = "AdaptPingWarning"
    pingGui.ResetOnSpawn = false
    pingGui.IgnoreGuiInset = true
    pingGui.DisplayOrder = 999
    pingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pingGui.Parent = pgPing

    -- The warning banner (red, original look)
    local banner = Instance.new("Frame", pingGui)
    banner.Name = "HighPingBanner"
    banner.Size = UDim2.new(0, 320, 0, 44)
    banner.AnchorPoint = Vector2.new(0.5, 0)
    banner.Position = UDim2.new(0.5, 0, 0, -60)
    banner.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    banner.BorderSizePixel = 0
    banner.Visible = false
    banner.ZIndex = 100

    local bCorner = Instance.new("UICorner", banner)
    bCorner.CornerRadius = UDim.new(0, 11)

    local bStroke = Instance.new("UIStroke", banner)
    bStroke.Color = Color3.fromRGB(255, 80, 80)
    bStroke.Thickness = 1.5
    bStroke.Transparency = 0.1
    bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Subtle vertical gradient for depth (lit from top → darker at bottom).
    -- Original had horizontal rotation which was flat; vertical reads as dimensional.
    local bGrad = Instance.new("UIGradient", banner)
    bGrad.Rotation = 90
    bGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(210, 50, 55)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 25, 25)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(140, 18, 18)),
    })

    -- Warning icon (left)
    local icon = Instance.new("TextLabel", banner)
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "⚠"
    icon.TextColor3 = Color3.fromRGB(255, 230, 80)
    icon.Font = Enum.Font.GothamBlack
    icon.TextSize = 22
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.TextYAlignment = Enum.TextYAlignment.Center
    icon.ZIndex = 101

    -- Main warning text
    local mainTxt = Instance.new("TextLabel", banner)
    mainTxt.Size = UDim2.new(1, -54, 0, 18)
    mainTxt.Position = UDim2.new(0, 44, 0, 5)
    mainTxt.BackgroundTransparency = 1
    mainTxt.Text = "HIGH PING - DON'T DUEL"
    mainTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainTxt.Font = Enum.Font.GothamBlack
    mainTxt.TextSize = 13
    mainTxt.TextXAlignment = Enum.TextXAlignment.Left
    mainTxt.TextYAlignment = Enum.TextYAlignment.Center
    mainTxt.ZIndex = 101

    -- Sub text with ping value
    local subTxt = Instance.new("TextLabel", banner)
    subTxt.Size = UDim2.new(1, -54, 0, 14)
    subTxt.Position = UDim2.new(0, 44, 0, 23)
    subTxt.BackgroundTransparency = 1
    subTxt.Text = "0ms"
    subTxt.TextColor3 = Color3.fromRGB(255, 220, 220)
    subTxt.Font = Enum.Font.GothamBold
    subTxt.TextSize = 11
    subTxt.TextXAlignment = Enum.TextXAlignment.Left
    subTxt.TextYAlignment = Enum.TextYAlignment.Center
    subTxt.ZIndex = 101

    -- State
    local shown        = false
    local dismissCoro  = nil
    local pulseConn    = nil
    local hasWarned    = false

    local function getPing()
        local p = 0
        pcall(function()
            local stat = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
            if stat then p = math.floor(stat:GetValue() or 0) end
        end)
        return p
    end

    local function stopPulse()
        if pulseConn then pulseConn:Disconnect(); pulseConn = nil end
        bStroke.Transparency = 0.1
    end

    local function startPulse()
        if pulseConn then return end
        local t0 = tick()
        pulseConn = RunService.Heartbeat:Connect(function()
            if not banner.Visible then return end
            local t = (math.sin((tick() - t0) * 4) + 1) * 0.5
            bStroke.Transparency = 0.05 + t * 0.3
        end)
    end

    local function hideBanner()
        if not shown then return end
        shown = false
        stopPulse()
        TS:Create(banner, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -60)
        }):Play()
        task.delay(0.32, function()
            if not shown then banner.Visible = false end
        end)
    end

    local function showBanner(ping)
        if shown then return end
        shown = true
        subTxt.Text = ping .. "ms (over " .. PING_THRESHOLD .. "ms)"
        banner.Position = UDim2.new(0.5, 0, 0, -60)
        banner.Visible = true

        TS:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, 14)
        }):Play()
        startPulse()

        if dismissCoro then pcall(task.cancel, dismissCoro) end
        dismissCoro = task.delay(DISMISS_AFTER, function()
            hideBanner()
        end)
    end

    -- Main loop: show once per spike (re-arms when ping recovers below threshold)
    task.spawn(function()
        while pingGui.Parent do
            local ping = getPing()
            if ping >= PING_THRESHOLD then
                if not hasWarned then
                    hasWarned = true
                    showBanner(ping)
                end
                if shown then
                    subTxt.Text = ping .. "ms (over " .. PING_THRESHOLD .. "ms)"
                end
            else
                hasWarned = false
            end
            task.wait(CHECK_INTERVAL)
        end
    end)

    _G.AdaptPingWarning = {
        setThreshold = function(v)
            local n = tonumber(v)
            if n and n > 0 then PING_THRESHOLD = n end
        end,
        getThreshold = function() return PING_THRESHOLD end,
    }
end

NS,CS = 60,30
LAGGER_SPEED = 15
LAGGER_CARRY_SPEED = 24.5
speedMode,antiRagdollEnabled,infJumpEnabled = false,false,false
laggerToggled = false
laggerPhase = 0
medusaCounterEnabled = false
batCounterEnabled = false
unwalkEnabled = false
medusaDebounce,medusaLastUsed,dropActive = false,0,false
autoLeftEnabled,autoRightEnabled = false,false
antiKickEnabled = true -- Safe Mode: blocks Auto L/R + Aimbot during duel countdown or while holding brainrot
autoLeftSetVisual,autoRightSetVisual = nil,nil
speedLabel = nil
autoBatEnabled = false
autoSwingEnabled = false
autoBatSetVisual = nil
aimbotSpeed = 59
aimbotLaggerSpeed = 40
resetAutoBatMotion = nil
setBatCounterVisual = nil
startBatCounter,stopBatCounter = nil, nil
antiLagEnabled = false
removeAccessoriesEnabled = false
antiLagDescConn = nil
stretchRezEnabled = false
stretchRezConn = nil
setStretchRezVisual = nil
-- All extra AceDuels state lives in a single table to save local registers
V = {
	customFovEnabled=false, customFovValue=70, customFovConn=nil, setCustomFovVisual=nil, customFovBox=nil,
	skyTheme="Off", setSkyVisual=nil, skyValLbl=nil,
	ultraModeEnabled=false, setUltraModeVisual=nil,
	removeAccessoriesEnabledSep=false, setRemoveAccVisual=nil, removeAccConn=nil,
	customFontEnabled=false, setCustomFontVisual=nil,
	potatoGraphicsEnabled=false, setPotatoVisual=nil, potatoConn=nil,
	autoSaveEnabled=true, setAutoSaveVisual=nil,
	themeAccent=nil,  -- {R,G,B} 0-1 floats; nil = default blue
	sidebarArt="111278026666543",  -- default Ace Duels sidebar photo
}

-- Ace Duels intro music options
-- Direct .mp3 links uploaded to Catbox.
selectedIntroMusic = 1
_introEnabled = true
INTRO_MUSIC_OPTIONS = {
	{name="Song 1", url="https://files.catbox.moe/mzvrir.mp3", file="AceDuelsIntroSong_1.mp3"},
	{name="Song 2", url="https://files.catbox.moe/2a7jyx.mp3", file="AceDuelsIntroSong_2.mp3"},
	{name="Song 3", url="https://files.catbox.moe/rcgr9f.mp3", file="AceDuelsIntroSong_3.mp3"},
	{name="Song 4", url="https://files.catbox.moe/iknfuh.mp3", file="AceDuelsIntroSong_4.mp3"},
	{name="Song 5", url="https://files.catbox.moe/6eigoh.mp3", file="AceDuelsIntroSong_5.mp3"},
	{name="Song 6", url="https://files.catbox.moe/dvjtjk.mp3", file="AceDuelsIntroSong_6.mp3"},
	{name="Song 7", url="https://files.catbox.moe/iyw1cb.mp3", file="AceDuelsIntroSong_7.mp3"}
}

function getIntroSongName()
	local opt = INTRO_MUSIC_OPTIONS[selectedIntroMusic]
	return opt and opt.name or "No Songs Added"
end
introPreviewSound = nil
introPlaybackSound = nil
introPreviewToken = 0
introPlaybackToken = 0

function stopIntroPreview()
	introPreviewToken = introPreviewToken + 1
	if introPreviewSound then
		pcall(function() introPreviewSound:Stop() end)
		pcall(function() introPreviewSound:Destroy() end)
		introPreviewSound = nil
	end
end

function stopIntroPlayback()
	introPlaybackToken = introPlaybackToken + 1
	if introPlaybackSound then
		pcall(function() introPlaybackSound:Stop() end)
		pcall(function() introPlaybackSound:Destroy() end)
		introPlaybackSound = nil
	end
end

introSongCache = {}
introSongDownloading = {}

function _safeNotify(msg)
	if showActionNotification then pcall(function() showActionNotification(msg) end) end
end

function cacheIntroSong(option, allowDownload)
	if not option or not option.url or option.url == "" then return nil end
	if not (writefile and getcustomasset) then return nil end
	local fileName = option.file or ("AceDuelsIntroSong_" .. tostring(option.name or "song") .. ".mp3")

	local function loadExisting()
		if introSongCache[fileName] then return introSongCache[fileName] end
		local hasFile = false
		pcall(function() hasFile = isfile and isfile(fileName) end)
		if hasFile then
			local ok = pcall(function() introSongCache[fileName] = getcustomasset(fileName) end)
			if ok and introSongCache[fileName] then return introSongCache[fileName] end
		end
		return nil
	end

	local cached = loadExisting()
	if cached then return cached end
	if allowDownload == false then return nil end

	-- First-time executor fix:
	-- preloadIntroSongs() may already be downloading this exact file.
	-- The old code returned nil while downloading, so the intro tried to play nothing.
	if introSongDownloading[fileName] then
		local waitStart = tick()
		while introSongDownloading[fileName] and tick() - waitStart < 12 do
			task.wait(0.05)
		end
		cached = loadExisting()
		if cached then return cached end
	end

	introSongDownloading[fileName] = true
	local ok = pcall(function()
		local data = game:HttpGet(option.url)
		if data and #data > 0 then
			writefile(fileName, data)
			introSongCache[fileName] = getcustomasset(fileName)
		end
	end)
	introSongDownloading[fileName] = nil
	if ok and introSongCache[fileName] then return introSongCache[fileName] end
	return loadExisting()
end

function preloadIntroSongs()
	-- Cache the selected song first so the intro has the best chance to start with audio.
	task.spawn(function()
		cacheIntroSong(INTRO_MUSIC_OPTIONS[selectedIntroMusic], true)
		for _,option in ipairs(INTRO_MUSIC_OPTIONS) do
			if option ~= INTRO_MUSIC_OPTIONS[selectedIntroMusic] then
				cacheIntroSong(option, true)
				task.wait(0.05)
			end
		end
	end)
end

function makeIntroSoundFromId(soundId, name, parent)
	if not soundId then return nil end
	local sound = Instance.new("Sound")
	sound.Name = name or "AceDuelsIntroMusic"
	sound.Volume = 0.65
	sound.Looped = false
	sound.SoundId = soundId
	sound.Parent = parent or SoundService
	return sound
end

function createIntroSound(option,fileName,parent,allowDownload)
	if not option then return nil end
	local soundId = cacheIntroSong(option, allowDownload)
	if not soundId then return nil end
	return makeIntroSoundFromId(soundId, fileName, parent)
end

preloadIntroSongs()

function previewIntroMusic(index)
	stopIntroPreview()
	stopIntroPlayback()
	if not INTRO_MUSIC_OPTIONS[index] then
		_safeNotify("ADD SONG LINKS")
		return
	end
	local token = introPreviewToken
	task.spawn(function()
		local option = INTRO_MUSIC_OPTIONS[index]
		local sound = createIntroSound(option,"AceDuelsIntroPreview_"..tostring(token),SoundService,true)
		if token ~= introPreviewToken then
			if sound then sound:Destroy() end
			return
		end
		introPreviewSound = sound
		if not sound then _safeNotify("SONG LOADING..."); return end
		sound.TimePosition = 0
		pcall(function() sound:Play() end)
		task.delay(15,function()
			if token == introPreviewToken then stopIntroPreview() end
		end)
	end)
end

function playIntroMusic()
	stopIntroPreview()
	stopIntroPlayback()
	if not _introEnabled then return end
	local option = INTRO_MUSIC_OPTIONS[selectedIntroMusic]
	if not option then return end
	local token = introPlaybackToken
	task.spawn(function()
		-- Download/cache directly here so the selected intro song actually plays on first run.
		local sound = createIntroSound(option,"AceDuelsIntroMusic_"..tostring(token),SoundService,true)
		if token ~= introPlaybackToken or not _introEnabled then
			if sound then pcall(function() sound:Destroy() end) end
			return
		end
		introPlaybackSound = sound
		if not sound then
			_safeNotify("SONG FAILED")
			return
		end
		sound.TimePosition = 0
		local loadStart = tick()
		while sound and not sound.IsLoaded and tick() - loadStart < 10 do task.wait(0.05) end
		pcall(function()
			if sound.IsLoaded then
				sound:Play()
			else
				-- Still call Play after the wait; Roblox will start it if it finishes loading right after.
				sound:Play()
			end
		end)
		task.delay(15,function()
			if token == introPlaybackToken then stopIntroPlayback() end
		end)
	end)
end

setAccent_global = nil
setSidebarArt_global = nil
setPlayerESPVisual = nil
PlayerESP = {enabled = false, playerData = {}, conns = {}, discordText = "discord.gg/aceduels"}
DEFAULT_SIDEBAR_ART_ID = "111278026666543"
THEME_ACCENT = Color3.fromRGB(230, 230, 230)
THEME_ACCENT_DIM = Color3.fromRGB(145, 145, 145)
THEME_ACCENT_BRIGHT = Color3.fromRGB(255, 255, 255)
_themedCallbacks = {}
function trackTheme(fn)
	table.insert(_themedCallbacks, fn)
	pcall(fn, THEME_ACCENT)
end
function setAccent(c)
	THEME_ACCENT = c
	THEME_ACCENT_DIM = Color3.new(c.R * 0.65, c.G * 0.65, c.B * 0.65)
	THEME_ACCENT_BRIGHT = Color3.new(math.min(1, c.R + 0.3), math.min(1, c.G + 0.3), math.min(1, c.B + 0.3))
	for _, fn in ipairs(_themedCallbacks) do pcall(fn, c) end
end
setAccent_global = setAccent
SIDEBAR_ART_PRESETS = {
	{name = "Ace",   id = DEFAULT_SIDEBAR_ART_ID},
	{name = "Anime", id = "82028776918457"},
	{name = "Dark",  id = "115117078011241"},
}
CURRENT_ART_ID = (V.sidebarArt ~= "" and V.sidebarArt) or DEFAULT_SIDEBAR_ART_ID
startPlayerESP, stopPlayerESP = nil, nil
unwalkSavedAnimate = nil
_anyKeyListening = false
_keyListenGeneration = 0
autoTPEnabled = false
autoTPHeight = 20
autoTPConn = nil
setAutoTPVisual = nil
cursedResetRemote = nil
CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"
-- Removed external blacklist/kick checker.
pcall(function()
	if hookfunction and newcclosure then
		local oldFire
		oldFire=hookfunction(Instance.new("RemoteEvent").FireServer,newcclosure(function(self,...)
			if not cursedResetRemote and typeof(self)=="Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3)=="RE/" then cursedResetRemote=self end
			return oldFire(self,...)
		end))
	end
end)
task.spawn(function()
	task.wait(2)
	if cursedResetRemote then return end
	for _,desc in ipairs(game:GetDescendants()) do
		if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
	end
end)
function cursedInstaReset()
	if not cursedResetRemote then
		for _,desc in ipairs(game:GetDescendants()) do
			if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
		end
	end
	if not cursedResetRemote then return end
	local character=LP.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health<=0 then pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end);return end
	local resetDetected=false
	local conns={}
	if humanoid then
		table.insert(conns,humanoid.Died:Connect(function() resetDetected=true end))
		table.insert(conns,humanoid:GetPropertyChangedSignal("Health"):Connect(function() if humanoid.Health<=0 then resetDetected=true end end))
	end
	if character then table.insert(conns,character.AncestryChanged:Connect(function(_,parent) if not parent then resetDetected=true end end)) end
	task.spawn(function()
		for _=1,10 do
			if resetDetected then break end
			pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end)
			task.wait(0.05)
		end
		for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
	end)
end
KB = {
	DropBrainrot={kb=Enum.KeyCode.X,gp=nil},
	AutoLeft    ={kb=Enum.KeyCode.Z,gp=nil},
	AutoRight   ={kb=Enum.KeyCode.C,gp=nil},
	AutoBat     ={kb=Enum.KeyCode.E,gp=nil},
	AntiDesyncAutoBat={kb=nil,gp=nil},
	TPFloor     ={kb=Enum.KeyCode.F,gp=nil},
	InstaReset  ={kb=Enum.KeyCode.T,gp=nil},
	GuiHide     ={kb=Enum.KeyCode.LeftControl,gp=nil},
	SpeedToggle ={kb=Enum.KeyCode.Q,gp=nil},
	LaggerToggle={kb=Enum.KeyCode.R,gp=nil}
}
AP_L1,AP_L2 = Vector3.new(-476.47,-6.28,92.73),Vector3.new(-483.12,-4.95,94.81)
AP_R1,AP_R2 = Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
Steal = {
	AutoStealEnabled=false,StealMode="Normal",NormalRadius=60,SemiRadius=9,
	StealRadius=60,StealDuration=1.3,
	Data={}, plotCache={}, plotCacheTime={}, cachedPrompts={}, promptCacheTime=0
}
isStealing = false
stealStartTime = nil
lastStealTick = 0
_guiLocked = false
setLockGuiVisual = nil
_introEnabled = (_introEnabled ~= false)
selectedIntroMusic = selectedIntroMusic or 1
setIntroVisual = nil
setIntroSongVisual = nil
autoResetEnabled = false
setAutoResetVisual = nil
autoResetConns = {}
antiDesyncAutoBatEnabled = false
setAntiDesyncAutoBatVisual = nil
startAntiDesyncAutoBat, stopAntiDesyncAutoBat = nil, nil
noCamCollisionEnabled = false
noCamCollisionConn = nil
noCamCollisionParts = {}
setNoCamCollisionVisual = nil
hitHarderAnimEnabled = false
hitHarderAnimConn = nil
hitHarderOriginalAnims = {}
setHitHarderAnimVisual = nil
Conns = {autoSteal=nil,antiRag=nil,batCounter=nil,anchor={},progress=nil}
PLOT_CACHE_DURATION, PROMPT_CACHE_REFRESH, STEAL_COOLDOWN = 2, 0.15, 0.1
MEDUSA_COOLDOWN = 25
batCounterDebounce = false
progressRadLbl,progressFill,progressPct = nil, nil, nil
startSemiInstantSteal,stopSemiInstantSteal = nil, nil
startNormalSyncedSteal,stopNormalSyncedSteal = nil, nil
semiStealConn,semiStealRenderConn=nil,nil
normalStealRenderConn=nil
semiStealGeneration,normalStealGeneration=0,0
semiState={active=false,startTime=0,phase="idle",lastResultTime=0,success=false,fill=0}
normalStealState={active=false,startTime=0,phase="idle",lastResultTime=0,success=false,fill=0}
normalBarGui,normalBarFrame,normalBarFill,normalBarPercent,normalBarStroke = nil, nil, nil, nil, nil
STEAL_BAR_COLORS={
	PINK=Color3.fromRGB(255,92,181),BLUE=Color3.fromRGB(0,180,255),
	SUCCESS=Color3.fromRGB(120,255,190),FAIL=Color3.fromRGB(255,90,120),WHITE=Color3.fromRGB(255,255,255)
}
modeValLbl = nil
lastMoveDir = Vector3.new(0,0,0)
MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
	[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}
function getActiveMoveSpeed()
	return laggerToggled and (laggerPhase==2 and LAGGER_CARRY_SPEED or LAGGER_SPEED) or (speedMode and CS or NS)
end
function getAutoPathSpeed()
	return laggerToggled and LAGGER_SPEED or NS
end
function isRagdollState(hum)
	if not hum then return true end
	local st=hum:GetState()
	return hum.PlatformStand or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
end

function isMyPlotByName(plotName)
	local plots=workspace:FindFirstChild("Plots")
	if not plots then return false end
	local plot=plots:FindFirstChild(plotName)
	if not plot then return false end
	local sign=plot:FindFirstChild("PlotSign")
	if sign then
		local yb=sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") then
			return yb.Enabled==true
		end
	end
	return false
end
function resetProgressBar()
	if progressPct then progressPct.Text="0%" end
	if progressFill then
		progressFill.Size=UDim2.new(0,0,1,0);progressFill.BackgroundColor3=THEME_ACCENT
		local grad=progressFill:FindFirstChildWhichIsA("UIGradient")
		if grad then grad.Color=ColorSequence.new(THEME_ACCENT:Lerp(Color3.new(1,1,1),0.12),THEME_ACCENT:Lerp(Color3.new(0,0,0),0.32)) end
	end
end
function resetNormalStealBar()
	if normalBarFill then normalBarFill.Size=UDim2.fromScale(0,1) end
	if normalBarPercent then normalBarPercent.Text="READY" end
	if normalBarStroke then normalBarStroke.Color=Color3.fromRGB(100,100,100) end
end
function ensureNormalStealBar()
	if normalBarGui and normalBarGui.Parent then return end
	local playerGui=LP:WaitForChild("PlayerGui")
	local old=playerGui:FindFirstChild("ORsStealBarGui")
	if old then old:Destroy() end
	normalBarGui=Instance.new("ScreenGui")
	normalBarGui.Name="ORsStealBarGui";normalBarGui.ResetOnSpawn=false
	normalBarGui.ZIndexBehavior=Enum.ZIndexBehavior.Global;normalBarGui.Parent=playerGui
	normalBarFrame=Instance.new("Frame",normalBarGui)
	normalBarFrame.Name="GrabBarFrame";normalBarFrame.Size=UDim2.new(0,220,0,28)
	normalBarFrame.AnchorPoint=Vector2.new(0.5,1);normalBarFrame.Position=UDim2.new(0.5,0,1,-52)
	normalBarFrame.BackgroundColor3=Color3.new(0,0,0);normalBarFrame.BorderSizePixel=0;normalBarFrame.Active=true
	Instance.new("UICorner",normalBarFrame).CornerRadius=UDim.new(0,10)
	local frameGradient=Instance.new("UIGradient",normalBarFrame)
	frameGradient.Rotation=135
	frameGradient.Color=ColorSequence.new(Color3.fromRGB(16,16,18),Color3.new(0,0,0))
	normalBarStroke=Instance.new("UIStroke",normalBarFrame)
	normalBarStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;normalBarStroke.Thickness=2
	normalBarStroke.Color=Color3.fromRGB(100,100,100)
	normalBarPercent=Instance.new("TextLabel",normalBarFrame)
	normalBarPercent.Size=UDim2.new(0,100,1,0);normalBarPercent.Position=UDim2.new(0,10,0,0)
	normalBarPercent.BackgroundTransparency=1;normalBarPercent.Text="READY"
	normalBarPercent.TextColor3=Color3.fromRGB(230,230,230);normalBarPercent.Font=Enum.Font.GothamBold
	normalBarPercent.TextSize=11;normalBarPercent.TextXAlignment=Enum.TextXAlignment.Left;normalBarPercent.ZIndex=2
	local ghost=Instance.new("TextLabel",normalBarFrame)
	ghost.Size=UDim2.new(0,22,0,22);ghost.Position=UDim2.new(1,-26,0.5,-11)
	ghost.BackgroundTransparency=1;ghost.Text="👻";ghost.TextSize=14;ghost.ZIndex=2
	local barBg=Instance.new("Frame",normalBarFrame)
	barBg.Size=UDim2.new(1,-6,0,5);barBg.Position=UDim2.new(0,3,1,-7)
	barBg.BackgroundColor3=Color3.fromRGB(30,30,30);barBg.BorderSizePixel=0;barBg.ZIndex=2
	Instance.new("UICorner",barBg).CornerRadius=UDim.new(1,0)
	normalBarFill=Instance.new("Frame",barBg)
	normalBarFill.Size=UDim2.fromScale(0,1);normalBarFill.BackgroundColor3=Color3.fromRGB(230,230,230)
	normalBarFill.BorderSizePixel=0;normalBarFill.ZIndex=3
	Instance.new("UICorner",normalBarFill).CornerRadius=UDim.new(1,0)
	local dragging,dragStart,startPos,activeInput=false,nil,nil,nil
	normalBarFrame.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true;dragStart=input.Position;startPos=normalBarFrame.Position;activeInput=input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local delta=input.Position-dragStart
			normalBarFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input==activeInput then dragging=false;activeInput=nil end
	end)
	resetNormalStealBar()
end
function setCurrentStealRadius(v)
	Steal.StealRadius=v
	if Steal.StealMode=="Semi" then Steal.SemiRadius=v else Steal.NormalRadius=v end
	Steal.cachedPrompts={};Steal.promptCacheTime=0
	if progressRadLbl then progressRadLbl.Text=string.format("Radius: %.2g",v) end
end
function setStealMode(mode)
	local nextMode=(mode=="Semi") and "Semi" or "Normal"
	if nextMode=="Semi" then
		if stopNormalSyncedSteal then stopNormalSyncedSteal() end
	else
		if stopSemiInstantSteal then stopSemiInstantSteal(false) end
	end
	Steal.StealMode=nextMode
	Steal.StealRadius=(Steal.StealMode=="Semi") and (Steal.SemiRadius or 9) or (Steal.NormalRadius or 60)
	Steal.cachedPrompts={};Steal.promptCacheTime=0
	if progressRadLbl then progressRadLbl.Text=string.format("Radius: %.2g",Steal.StealRadius) end
end
-- ════════════════════════════════════════════════════════════════
-- AUTO STEAL — cr2123 style (NO teleport, NO turbo modifications,
-- proper plot+prompt cache, cooldown, 3-tier fallback firing)
-- ════════════════════════════════════════════════════════════════
nearestPromptCache, nearestPromptDist = nil, math.huge

function findNearestPrompt(radiusOverride)
	local c = LP.Character; if not c then return nil, math.huge end
	local root = c:FindFirstChild("HumanoidRootPart"); if not root then return nil, math.huge end
	local searchRadius=radiusOverride or Steal.StealRadius
	local ct = tick()
	-- fast path: use the cached prompt list if it's recent enough
	if ct - Steal.promptCacheTime < PROMPT_CACHE_REFRESH and #Steal.cachedPrompts > 0 then
		local np, nd = nil, math.huge
		for _, data in ipairs(Steal.cachedPrompts) do
			if data.spawn and data.spawn.Parent and data.prompt and data.prompt.Parent then
				local dist = (data.spawn.Position - root.Position).Magnitude
				if dist <= searchRadius and dist < nd then np = data.prompt; nd = dist end
			end
		end
		if np then return np, nd end
	end
	-- slow path: rebuild the cache by walking workspace.Plots
	Steal.cachedPrompts = {}; Steal.promptCacheTime = ct
	local plots = workspace:FindFirstChild("Plots"); if not plots then return nil, math.huge end
	local np, nd = nil, math.huge
	for _, plot in ipairs(plots:GetChildren()) do
		if isMyPlotByName(plot.Name) then continue end
		local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
		for _, pod in ipairs(pods:GetChildren()) do
			pcall(function()
				local base = pod:FindFirstChild("Base")
				local sp = base and base:FindFirstChild("Spawn")
				if sp then
					local att = sp:FindFirstChild("PromptAttachment")
					if att then
						for _, child in ipairs(att:GetChildren()) do
							if child:IsA("ProximityPrompt") then
								local dist = (sp.Position - root.Position).Magnitude
								table.insert(Steal.cachedPrompts, {prompt=child, spawn=sp})
								if dist <= searchRadius and dist < nd then np = child; nd = dist end
								break
							end
						end
					end
				end
			end)
		end
	end
	return np, nd
end

function executeSteal(prompt)
	local ct = tick()
	if ct - lastStealTick < STEAL_COOLDOWN then return end
	if isStealing then return end
	if not prompt or not prompt.Parent then return end
	-- cache callbacks ONCE per prompt
	if not Steal.Data[prompt] then
		Steal.Data[prompt] = {hold={}, trigger={}, ready=true}
		pcall(function()
			if type(getconnections)=="function" then
				for _, c2 in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
					if type(c2.Function)=="function" then table.insert(Steal.Data[prompt].hold, c2.Function) end
				end
				for _, c2 in ipairs(getconnections(prompt.Triggered)) do
					if type(c2.Function)=="function" then table.insert(Steal.Data[prompt].trigger, c2.Function) end
				end
			else
				Steal.Data[prompt].useFallback = true
			end
		end)
	end
	local data = Steal.Data[prompt]
	if not data.ready then return end
	data.ready = false; isStealing = true; stealStartTime = ct; lastStealTick = ct
	if Conns.progress then Conns.progress:Disconnect() end
	Conns.progress = RunService.Heartbeat:Connect(function()
		if not isStealing then Conns.progress:Disconnect();Conns.progress=nil;return end
		local prog = math.clamp((tick()-stealStartTime)/Steal.StealDuration, 0, 1)
		if progressFill then progressFill.Size = UDim2.new(prog, 0, 1, 0) end
		if progressPct then progressPct.Text = math.floor(prog*100).."%" end
	end)
	task.spawn(function()
		-- 3-tier fallback: getconnections → fireproximityprompt → InputHoldBegin/End
		local ok = false
		pcall(function()
			if not data.useFallback and #data.hold > 0 then
				for _, fn in ipairs(data.hold) do task.spawn(function() pcall(fn) end) end
				task.wait(Steal.StealDuration)
				for _, fn in ipairs(data.trigger) do task.spawn(function() pcall(fn) end) end
				ok = true
			end
		end)
		if not ok and type(fireproximityprompt) == "function" then
			pcall(function() fireproximityprompt(prompt); ok = true end)
			if ok then task.wait(Steal.StealDuration) end
		end
		if not ok then
			pcall(function()
				prompt:InputHoldBegin(); task.wait(Steal.StealDuration); prompt:InputHoldEnd()
			end)
		end
		task.wait(Steal.StealDuration * 0.3)
		if Conns.progress then Conns.progress:Disconnect();Conns.progress=nil end
		resetProgressBar()
		task.wait(0.05); data.ready = true
		isStealing = false
	end)
end

function startAutoSteal()
	if Conns.autoSteal then return end
	if Steal.StealMode=="Semi" then
		if startSemiInstantSteal then startSemiInstantSteal() end
		return
	end
	if stopSemiInstantSteal then stopSemiInstantSteal(false) end
	Conns.autoSteal = RunService.Heartbeat:Connect(function()
		if not Steal.AutoStealEnabled or isStealing then return end
		local p = findNearestPrompt()
		if p then executeSteal(p) end
	end)
end
function stopAutoSteal()
	if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
	if stopSemiInstantSteal then stopSemiInstantSteal(false) end
	if Conns.progress then Conns.progress:Disconnect();Conns.progress=nil end
	isStealing = false; lastStealTick = 0
	Steal.plotCache = {}; Steal.plotCacheTime = {}; Steal.cachedPrompts = {}
	resetProgressBar()
end

-- Semi Instant Steal: Synchronizer-backed logic from FREE AUTO STEAL ACE DUELS.
-- Targets the exact plot/slot animal, primes from 80 studs, holds for 1.3s,
-- then fires after the player enters the selected close radius.
do
	local HOLD_MIN,HOLD_MAX,ENTRY_DELAY,PRIME_RANGE,COOLDOWN=1.3,2.6,0.3,80,0.05
	local ReplicatedStorage=game:GetService("ReplicatedStorage")
	local Packages=ReplicatedStorage:WaitForChild("Packages")
	local Datas=ReplicatedStorage:WaitForChild("Datas")
	local AnimalsData={}
	pcall(function()
		local loaded=require(Datas:WaitForChild("Animals"))
		if type(loaded)=="table" then AnimalsData=loaded end
	end)
	local plots=workspace:WaitForChild("Plots")
	local synchronizer=Packages:WaitForChild("Synchronizer")
	local syncChannelFolder=synchronizer:WaitForChild("Channel")
	local syncRouteRemote=synchronizer:WaitForChild("CommunicationRoute")
	local syncRequestData=synchronizer:FindFirstChild("RequestData")
	local plotAnimalSync={caches={},connections={}}
	local allAnimalsCache={}
	local promptMemoryCache={}
	local semiInternalStealCache={}
	local normalInternalStealCache={}
	local normalAnimalCache={}
	local normalPromptMemoryCache={}

	local function splitSyncPath(path)
		if typeof(path)=="table" then return path end
		local out={}
		for part in string.gmatch(tostring(path),"[^%.]+") do table.insert(out,tonumber(part) or part) end
		return out
	end
	local function resolveSyncPath(path,root)
		local current,parent,key=root,nil,nil
		for _,part in ipairs(splitSyncPath(path)) do parent=current;key=part;current=current and current[part] or nil end
		return current,parent,key
	end
	local function applyPlotSyncDiff(channelName,packet)
		local cache=plotAnimalSync.caches[channelName]
		if typeof(cache)~="table" then return end
		local path,action,a,b=packet[1],packet[2],packet[3],packet[4]
		local current,parent,key=resolveSyncPath(path,cache)
		if action=="Changed" then if parent~=nil then parent[key]=a end
		elseif action=="ArrayInsert" then if current~=nil then table.insert(current,b,a) end
		elseif action=="ArrayRemoved" then if current~=nil then table.remove(current,b) end
		elseif action=="DictionaryInsert" then if current~=nil then current[b]=a end
		elseif action=="DictionaryRemoved" then if current~=nil then current[b]=nil end end
	end
	local function attachPlotChannel(remote)
		if plotAnimalSync.connections[remote] then return end
		local channelName=tostring(remote.Name)
		if not plots:FindFirstChild(channelName) then return end
		if syncRequestData and plotAnimalSync.caches[channelName]==nil then
			local ok,data=pcall(function() return syncRequestData:InvokeServer(channelName) end)
			plotAnimalSync.caches[channelName]=(ok and typeof(data)=="table") and data or {}
		elseif plotAnimalSync.caches[channelName]==nil then plotAnimalSync.caches[channelName]={} end
		plotAnimalSync.connections[remote]=remote.OnClientEvent:Connect(function(queue)
			for _,packet in ipairs(queue) do applyPlotSyncDiff(channelName,packet) end
		end)
	end
	local function detachPlotChannel(channelName)
		for remote,conn in pairs(plotAnimalSync.connections) do
			if tostring(remote.Name)==tostring(channelName) then
				conn:Disconnect();plotAnimalSync.connections[remote]=nil;plotAnimalSync.caches[tostring(channelName)]=nil;break
			end
		end
	end
	for _,child in ipairs(syncChannelFolder:GetChildren()) do if child:IsA("RemoteEvent") then attachPlotChannel(child) end end
	syncChannelFolder.ChildAdded:Connect(function(child) if child:IsA("RemoteEvent") then attachPlotChannel(child) end end)
	syncRouteRemote.OnClientEvent:Connect(function(actions)
		for _,action in ipairs(actions) do
			local kind,channelName=action[1],tostring(action[2])
			if plots:FindFirstChild(channelName) then
				if kind=="ListenerAdded" then
					local remote=syncChannelFolder:FindFirstChild(channelName)
					if remote and remote:IsA("RemoteEvent") then attachPlotChannel(remote) end
				elseif kind=="ListenerRemoved" then detachPlotChannel(channelName) end
			end
		end
	end)

	local function getPlotOwner(plot)
		local sign=plot:FindFirstChild("PlotSign")
		local frame=sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame")
		local label=frame and frame:FindFirstChild("TextLabel")
		if not label or label.Text=="Empty Base" then return nil end
		return label.Text:gsub("'s [Bb]ase$",""):gsub("%s+$","")
	end
	local function isMyBaseAnimal(animalData)
		local plot=animalData and animalData.plot and plots:FindFirstChild(animalData.plot)
		return plot and getPlotOwner(plot)==LP.DisplayName or false
	end
	local function getAnimalPodium(animalData)
		local plot=plots:FindFirstChild(animalData.plot)
		local podiums=plot and plot:FindFirstChild("AnimalPodiums")
		return podiums and podiums:FindFirstChild(animalData.slot) or nil
	end
	local function getAnimalPosition(animalData)
		local podium=getAnimalPodium(animalData)
		return podium and podium:GetPivot().Position or nil
	end
	local function distToAnimal(animalData)
		local char=LP.Character
		local root=char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
		local pos=getAnimalPosition(animalData)
		return root and pos and (root.Position-pos).Magnitude or math.huge
	end
	local function isMyNormalPlot(plotName)
		local plot=plots:FindFirstChild(plotName)
		local sign=plot and plot:FindFirstChild("PlotSign")
		local yourBase=sign and sign:FindFirstChild("YourBase")
		return yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled==true or false
	end
	local function scanAllNormalPlots()
		local newCache={}
		for _,plot in ipairs(plots:GetChildren()) do
			if plot:IsA("Model") and not isMyNormalPlot(plot.Name) then
				local podiums=plot:FindFirstChild("AnimalPodiums")
				if podiums then
					for _,podium in ipairs(podiums:GetChildren()) do
						if podium:IsA("Model") and podium:FindFirstChild("Base") then
							table.insert(newCache,{name=podium.Name,plot=plot.Name,slot=podium.Name,worldPosition=podium:GetPivot().Position,uid=plot.Name.."_"..podium.Name})
						end
					end
				end
			end
		end
		normalAnimalCache=newCache
		normalPromptMemoryCache={}
	end
	local function findNormalPrompt(animalData)
		if not animalData then return nil end
		local cached=normalPromptMemoryCache[animalData.uid]
		if cached and cached.Parent then return cached end
		local plot=plots:FindFirstChild(animalData.plot)
		local podiums=plot and plot:FindFirstChild("AnimalPodiums")
		local podium=podiums and podiums:FindFirstChild(animalData.slot)
		local base=podium and podium:FindFirstChild("Base")
		local spawn=base and base:FindFirstChild("Spawn")
		if not spawn then return nil end
		local attachment=spawn:FindFirstChild("PromptAttachment")
		if attachment then
			for _,prompt in ipairs(attachment:GetChildren()) do
				if prompt:IsA("ProximityPrompt") then normalPromptMemoryCache[animalData.uid]=prompt;return prompt end
			end
		end
		for _,descendant in ipairs(spawn:GetDescendants()) do
			if descendant:IsA("ProximityPrompt") then normalPromptMemoryCache[animalData.uid]=descendant;return descendant end
		end
	end
	local function pickClosestNormalAnimal()
		local char=LP.Character
		local root=char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
		if not root then return nil,math.huge end
		local best,bestDist=nil,math.huge
		for _,animalData in ipairs(normalAnimalCache) do
			if not isMyNormalPlot(animalData.plot) and animalData.worldPosition then
				local dist=(root.Position-animalData.worldPosition).Magnitude
				if dist<bestDist then best,bestDist=animalData,dist end
			end
		end
		return best,bestDist
	end
	local function findPromptForAnimal(animalData)
		local cached=promptMemoryCache[animalData.uid]
		if cached and cached.Parent then return cached end
		local podium=getAnimalPodium(animalData)
		local base=podium and podium:FindFirstChild("Base")
		local spawn=base and base:FindFirstChild("Spawn")
		local attachment=spawn and spawn:FindFirstChild("PromptAttachment")
		if not attachment then return nil end
		for _,prompt in ipairs(attachment:GetChildren()) do
			if prompt:IsA("ProximityPrompt") then promptMemoryCache[animalData.uid]=prompt;return prompt end
		end
	end
	local function pickClosestAnimal()
		local char=LP.Character
		local root=char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
		if not root then return nil end
		local best,bestDist=nil,math.huge
		for _,animalData in ipairs(allAnimalsCache) do
			if not isMyBaseAnimal(animalData) then
				local pos=getAnimalPosition(animalData)
				local dist=pos and (root.Position-pos).Magnitude or math.huge
				if dist<=PRIME_RANGE and dist<bestDist then best,bestDist=animalData,dist end
			end
		end
		return best
	end
	local function scanAllPlots()
		local newCache={}
		for _,plot in ipairs(plots:GetChildren()) do
			local cache=plotAnimalSync.caches[plot.Name]
			local animalList=cache and cache.AnimalList
			if typeof(animalList)=="table" then
				for slot,animalData in pairs(animalList) do
					if type(animalData)=="table" then
						local animalName=animalData.Index
						local animalInfo=AnimalsData[animalName]
						if animalInfo then
							table.insert(newCache,{name=animalInfo.DisplayName or animalName,plot=plot.Name,slot=tostring(slot),uid=plot.Name.."_"..tostring(slot)})
						end
					end
				end
			end
		end
		allAnimalsCache=newCache
	end
	local function buildSemiCallbacks(prompt)
		if semiInternalStealCache[prompt] then return end
		local data={holdCallbacks={},triggerCallbacks={},ready=true}
		local okHold,holdConnections=pcall(getconnections,prompt.PromptButtonHoldBegan)
		if okHold and type(holdConnections)=="table" then
			for _,connection in ipairs(holdConnections) do
				if type(connection.Function)=="function" then table.insert(data.holdCallbacks,connection.Function) end
			end
		end
		local okTrigger,triggerConnections=pcall(getconnections,prompt.Triggered)
		if okTrigger and type(triggerConnections)=="table" then
			for _,connection in ipairs(triggerConnections) do
				if type(connection.Function)=="function" then table.insert(data.triggerCallbacks,connection.Function) end
			end
		end
		if #data.holdCallbacks>0 or #data.triggerCallbacks>0 then semiInternalStealCache[prompt]=data end
	end
	local function buildNormalCallbacks(prompt)
		if normalInternalStealCache[prompt] then return end
		local data={holdCallbacks={},triggerCallbacks={},ready=true}
		local okHold,holdConnections=pcall(getconnections,prompt.PromptButtonHoldBegan)
		if okHold and type(holdConnections)=="table" then
			for _,connection in ipairs(holdConnections) do
				if type(connection.Function)=="function" then table.insert(data.holdCallbacks,connection.Function) end
			end
		end
		local okTrigger,triggerConnections=pcall(getconnections,prompt.Triggered)
		if okTrigger and type(triggerConnections)=="table" then
			for _,connection in ipairs(triggerConnections) do
				if type(connection.Function)=="function" then table.insert(data.triggerCallbacks,connection.Function) end
			end
		end
		if #data.holdCallbacks>0 or #data.triggerCallbacks>0 then normalInternalStealCache[prompt]=data end
	end
	local function beginSemiSteal(prompt,animalData)
		if not prompt or not prompt.Parent then return false end
		buildSemiCallbacks(prompt)
		local data=semiInternalStealCache[prompt]
		if not data or not data.ready then return false end
		local generation=semiStealGeneration
		data.ready=false;semiState.active=true;semiState.startTime=tick();semiState.phase="holding"
		task.spawn(function()
			for _,fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
			task.wait(HOLD_MIN)
			if generation~=semiStealGeneration then data.ready=true;return end
			semiState.phase="waitingRange"
			local alreadyInRange=distToAnimal(animalData)<=Steal.SemiRadius
			local fired=false
			while generation==semiStealGeneration and Steal.StealMode=="Semi" and Steal.AutoStealEnabled and prompt.Parent do
				local elapsed=tick()-semiState.startTime
				if elapsed>HOLD_MAX then break end
				if distToAnimal(animalData)<=Steal.SemiRadius then
					if not alreadyInRange then task.wait(ENTRY_DELAY) end
					for _,fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
					fired=true;break
				end
				task.wait(0.03)
			end
			if generation==semiStealGeneration then
				semiState.success=fired;semiState.phase="idle"
				semiState.active=false;semiState.lastResultTime=tick()
			end
			task.wait(COOLDOWN);data.ready=true
		end)
		return true
	end
	local function beginNormalSteal(prompt,animalData)
		if not prompt or not prompt.Parent then return false end
		buildNormalCallbacks(prompt)
		local data=normalInternalStealCache[prompt]
		if not data or not data.ready then return false end
		local generation=normalStealGeneration
		data.ready=false;isStealing=true;stealStartTime=tick();lastStealTick=stealStartTime
		normalStealState.active=true;normalStealState.startTime=stealStartTime
		normalStealState.phase="holding";normalStealState.success=false
		ensureNormalStealBar()
		if normalBarPercent then normalBarPercent.Text=animalData and animalData.name or "STEAL..." end
		if normalBarStroke then normalBarStroke.Color=Color3.fromRGB(255,255,255) end
		task.spawn(function()
			for _,fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
			local elapsed=0
			while elapsed<Steal.StealDuration and generation==normalStealGeneration do elapsed=elapsed+task.wait() end
			local fired=generation==normalStealGeneration and Steal.StealMode=="Normal" and Steal.AutoStealEnabled and prompt.Parent~=nil
			if fired then for _,fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end end
			task.wait(0.01)
			if generation==normalStealGeneration then
				normalStealState.success=fired
				normalStealState.phase="idle"
				normalStealState.active=false;normalStealState.lastResultTime=0;normalStealState.fill=0
				isStealing=false
			end
			resetNormalStealBar()
			data.ready=true
		end)
		return true
	end
	local function updateNormalBar(dt)
		if Steal.StealMode~="Normal" then return end
		ensureNormalStealBar()
		local target,color=0,STEAL_BAR_COLORS.WHITE
		if normalStealState.active then
			target=math.clamp((tick()-normalStealState.startTime)/Steal.StealDuration,0,1)
		end
		normalStealState.fill=target
		local shown=math.clamp(normalStealState.fill,0,1)
		if normalBarFill then
			normalBarFill.Size=UDim2.fromScale(shown,1)
			if normalStealState.active then
				local pulse=230+math.floor(math.sin((tick()%1)*math.pi*6)*25)
				normalBarFill.BackgroundColor3=Color3.fromRGB(pulse,230,255)
			else normalBarFill.BackgroundColor3=Color3.fromRGB(230,230,230) end
		end
		if normalBarPercent then normalBarPercent.Text=normalStealState.active and (tostring(math.floor(shown*100)).."%") or "READY" end
		if normalBarStroke then normalBarStroke.Color=normalStealState.active and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100) end
	end
	local function updateSemiBar(dt)
		if Steal.StealMode~="Semi" or not progressFill or not progressPct then return end
		local recent=semiState.lastResultTime>0 and tick()-semiState.lastResultTime<0.75
		local target,color=0,THEME_ACCENT
		if semiState.active then
			target=math.clamp((tick()-semiState.startTime)/HOLD_MIN,0,1)
		elseif recent then target=1 end
		semiState.fill=semiState.fill+(target-semiState.fill)*math.min((dt or 0.016)*14,1)
		local shown=math.clamp(semiState.fill,0,1)
		progressFill.Size=UDim2.new(shown,0,1,0);progressFill.BackgroundColor3=color
		local grad=progressFill:FindFirstChildWhichIsA("UIGradient")
		if grad then grad.Color=ColorSequence.new(color:Lerp(STEAL_BAR_COLORS.WHITE,0.18),color:Lerp(Color3.new(0,0,0),0.38)) end
		progressPct.Text=tostring(math.floor(shown*100+0.5)).."%";progressPct.TextColor3=STEAL_BAR_COLORS.WHITE
	end
	startSemiInstantSteal=function()
		if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
		if normalStealRenderConn then normalStealRenderConn:Disconnect();normalStealRenderConn=nil end
		normalStealGeneration=normalStealGeneration+1
		normalStealState.active=false;normalStealState.phase="idle";normalStealState.fill=0;isStealing=false
		if normalBarGui then normalBarGui.Enabled=false end
		if semiStealConn then return end
		semiStealGeneration=semiStealGeneration+1
		semiState.fill=0;resetProgressBar();scanAllPlots()
		semiStealRenderConn=RunService.RenderStepped:Connect(updateSemiBar)
		semiStealConn=RunService.Heartbeat:Connect(function()
			if Steal.StealMode~="Semi" or not Steal.AutoStealEnabled or semiState.active then return end
			local target=pickClosestAnimal();if not target then return end
			local prompt=findPromptForAnimal(target);if prompt then beginSemiSteal(prompt,target) end
		end)
	end
	startNormalSyncedSteal=function()
		if semiStealConn then semiStealConn:Disconnect();semiStealConn=nil end
		if semiStealRenderConn then semiStealRenderConn:Disconnect();semiStealRenderConn=nil end
		semiStealGeneration=semiStealGeneration+1
		semiState.active=false;semiState.phase="idle";semiState.fill=0
		if Conns.autoSteal then return end
		normalStealGeneration=normalStealGeneration+1
		Steal.StealDuration=1.3
		if not Steal.NormalRadius then Steal.NormalRadius=60 end
		Steal.StealRadius=Steal.NormalRadius
		ensureNormalStealBar();normalBarGui.Enabled=true;resetNormalStealBar()
		normalStealState.fill=0;normalStealState.phase="idle";normalStealState.lastResultTime=0;resetProgressBar();scanAllNormalPlots()
		if normalStealRenderConn then normalStealRenderConn:Disconnect() end
		normalStealRenderConn=RunService.RenderStepped:Connect(updateNormalBar)
		Conns.autoSteal=RunService.Heartbeat:Connect(function()
			if Steal.StealMode~="Normal" or not Steal.AutoStealEnabled or isStealing then return end
			local target,dist=pickClosestNormalAnimal();if not target or dist>Steal.NormalRadius then return end
			local prompt=findNormalPrompt(target);if prompt then beginNormalSteal(prompt,target) end
		end)
	end
	stopNormalSyncedSteal=function()
		if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
		if normalStealRenderConn then normalStealRenderConn:Disconnect();normalStealRenderConn=nil end
		normalStealGeneration=normalStealGeneration+1
		isStealing=false
		normalStealState.active=false;normalStealState.phase="idle";normalStealState.fill=0;normalStealState.lastResultTime=0
		resetNormalStealBar()
	end
	stopSemiInstantSteal=function(resetBar)
		if semiStealConn then semiStealConn:Disconnect();semiStealConn=nil end
		if semiStealRenderConn then semiStealRenderConn:Disconnect();semiStealRenderConn=nil end
		semiStealGeneration=semiStealGeneration+1
		semiState.active=false;semiState.phase="idle";semiState.fill=0
		if resetBar~=false then resetProgressBar() end
		if progressRadLbl then progressRadLbl.TextColor3=Color3.fromRGB(190,190,190) end
	end
	task.spawn(function() while task.wait(5) do scanAllPlots();scanAllNormalPlots() end end)
end
RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			for _,part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide=false end
			end
		end
	end
end)
RunService.RenderStepped:Connect(function()
	local char=LP.Character;if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	if isRagdollState(hum) then lastMoveDir=Vector3.new(0,0,0);return end
	if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled then
		local md=hum.MoveDirection
		local spd=getActiveMoveSpeed()
		if md.Magnitude>0 then
			lastMoveDir=md
			hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
		elseif antiRagdollEnabled and lastMoveDir.Magnitude>0 then
			local anyHeld=false
			for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true;break end end
			if anyHeld then hrp.Velocity=Vector3.new(lastMoveDir.X*spd,hrp.Velocity.Y,lastMoveDir.Z*spd) end
		end
	end
	if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
end)
alConn,arConn=nil,nil
alPhase,arPhase=1,1
function stopAutoLeft()
	if alConn then alConn:Disconnect();alConn=nil end;alPhase=1
	local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
	if autoLeftSetVisual then autoLeftSetVisual(false) end
end
function stopAutoRight()
	if arConn then arConn:Disconnect();arConn=nil end;arPhase=1
	local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
	if autoRightSetVisual then autoRightSetVisual(false) end
end
function startAutoLeft()
	if alConn then alConn:Disconnect() end;alPhase=1
	alConn=RunService.Heartbeat:Connect(function()
		if not autoLeftEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
		local spd=getAutoPathSpeed()
		if alPhase==1 then
			local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				alPhase=2
				local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
				return
			end
			local d=AP_L1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif alPhase==2 then
			local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoLeftEnabled=false;if alConn then alConn:Disconnect();alConn=nil end
				alPhase=1;if autoLeftSetVisual then autoLeftSetVisual(false) end;return
			end
			local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end
function startAutoRight()
	if arConn then arConn:Disconnect() end;arPhase=1
	arConn=RunService.Heartbeat:Connect(function()
		if not autoRightEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
		local spd=getAutoPathSpeed()
		if arPhase==1 then
			local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				arPhase=2
				local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
				return
			end
			local d=AP_R1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif arPhase==2 then
			local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoRightEnabled=false;if arConn then arConn:Disconnect();arConn=nil end
				arPhase=1;if autoRightSetVisual then autoRightSetVisual(false) end;return
			end
			local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end
function setupSpeedIndicator(char)
	local head=char:WaitForChild("Head",5);if not head then return end
	local bb=Instance.new("BillboardGui",head)
	bb.Size=UDim2.new(0,200,0,82);bb.StudsOffset=Vector3.new(0,3,0);bb.AlwaysOnTop=true

	-- Hit/ragdoll countdown sits above the Discord text with no box.
	ragdollCountdownFrame=nil
	ragdollCountdownLabel=Instance.new("TextLabel",bb)
	ragdollCountdownLabel.Size=UDim2.new(1,0,0,28)
	ragdollCountdownLabel.Position=UDim2.new(0,0,0,0)
	ragdollCountdownLabel.BackgroundTransparency=1
	ragdollCountdownLabel.Visible=false
	ragdollCountdownLabel.Text=""
	ragdollCountdownLabel.TextColor3=Color3.fromRGB(80,255,120)
	ragdollCountdownLabel.Font=Enum.Font.GothamBlack
	ragdollCountdownLabel.TextSize=24
	ragdollCountdownLabel.TextStrokeTransparency=0
	ragdollCountdownLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
	ragdollCountdownLabel.TextXAlignment=Enum.TextXAlignment.Center

	-- Discord text under countdown
	local discordLbl=Instance.new("TextLabel",bb)
	discordLbl.Size=UDim2.new(1,0,0,22)
	discordLbl.Position=UDim2.new(0,0,0,30)
	discordLbl.BackgroundTransparency=1
	discordLbl.Text="discord.gg/aceduels"
	discordLbl.TextColor3=Color3.fromRGB(255,255,255)
	discordLbl.Font=Enum.Font.GothamBlack;discordLbl.TextScaled=true
	discordLbl.TextStrokeTransparency=0;discordLbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
	-- Speed below
	speedLabel=Instance.new("TextLabel",bb)
	speedLabel.Size=UDim2.new(1,0,0,28)
	speedLabel.Position=UDim2.new(0,0,0,54)
	speedLabel.BackgroundTransparency=1
	speedLabel.Text="Speed: 0";speedLabel.TextColor3=THEME_ACCENT
	speedLabel.Font=Enum.Font.GothamBlack;speedLabel.TextScaled=true
	speedLabel.TextStrokeTransparency=0;speedLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
	trackTheme(function(c) if speedLabel and speedLabel.Parent then speedLabel.TextColor3 = c end end)
end
function startAntiRagdoll()
	if Conns.antiRag then return end

	Conns.antiRag = RunService.Heartbeat:Connect(function()
		if not antiRagdollEnabled then return end

		local char = LP.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not (hum and root) then return end

		local s = hum:GetState()
		local ragdolled = (
			s == Enum.HumanoidStateType.Physics
			or s == Enum.HumanoidStateType.Ragdoll
			or s == Enum.HumanoidStateType.FallingDown
		)

		local endTime = LP:GetAttribute("RagdollEndTime")
		if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then
			ragdolled = true
		end

		if ragdolled then
			pcall(function()
				LP:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
			end)

			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
					d:Destroy()
				end
			end

			for _, obj in ipairs(char:GetDescendants()) do
				if obj:IsA("Motor6D") and obj.Enabled == false then
					obj.Enabled = true
				end
			end

			if hum.Health > 0 then
				hum:ChangeState(Enum.HumanoidStateType.Running)
			end

			workspace.CurrentCamera.CameraSubject = hum
			root.Anchored = false
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end)
end

function stopAntiRagdoll()
	if Conns.antiRag then
		Conns.antiRag:Disconnect()
		Conns.antiRag = nil
	end
end

-- =========================================================
-- PLAYER ESP — clean white/grey outline + rounded name/speed tag only
-- =========================================================
do
	local ESP_FILL = Color3.fromRGB(35, 35, 35)
	local ESP_OUTLINE = Color3.fromRGB(245, 245, 245)
	local ESP_BOX = Color3.fromRGB(18, 18, 18)
	local ESP_BOX_STROKE = Color3.fromRGB(170, 170, 170)
	local ESP_TEXT = Color3.fromRGB(255, 255, 255)
	local ESP_SUBTEXT = Color3.fromRGB(180, 180, 180)

	local function _espCleanupPlayer(player)
		local d = PlayerESP.playerData[player]
		if not d then return end
		if d.highlight then pcall(function() d.highlight:Destroy() end) end
		if d.billboard then pcall(function() d.billboard:Destroy() end) end
		if d.conns then
			for _, c in ipairs(d.conns) do pcall(function() c:Disconnect() end) end
		end
		PlayerESP.playerData[player] = nil
	end

	local function _espSetupCharacter(player, char)
		if not PlayerESP.enabled or player == LP then return end
		_espCleanupPlayer(player)
		if not char or not char.Parent then return end

		local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
		local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 5)
		if not hrp or not head then return end

		local hl = Instance.new("Highlight")
		hl.Name = "AceDuelsESP"
		hl.Adornee = char
		hl.FillColor = ESP_FILL
		hl.FillTransparency = 0.72
		hl.OutlineColor = ESP_OUTLINE
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = char

		local bb = Instance.new("BillboardGui")
		bb.Name = "AceDuelsESPTag"
		bb.Adornee = head
		bb.Size = UDim2.new(0, 124, 0, 34)
		bb.StudsOffset = Vector3.new(0, 2.7, 0)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Parent = head

		local box = Instance.new("Frame", bb)
		box.Size = UDim2.new(1, 0, 1, 0)
		box.Position = UDim2.new(0, 0, 0, 0)
		box.BackgroundColor3 = ESP_BOX
		box.BackgroundTransparency = 0.14
		box.BorderSizePixel = 0

		local corner = Instance.new("UICorner", box)
		corner.CornerRadius = UDim.new(0, 9)

		local stroke = Instance.new("UIStroke", box)
		stroke.Color = ESP_BOX_STROKE
		stroke.Thickness = 1
		stroke.Transparency = 0.08

		local nLbl = Instance.new("TextLabel", box)
		nLbl.Size = UDim2.new(1, -10, 0, 17)
		nLbl.Position = UDim2.new(0, 5, 0, 2)
		nLbl.BackgroundTransparency = 1
		nLbl.Text = "0 speed"
		nLbl.TextColor3 = ESP_TEXT
		nLbl.Font = Enum.Font.GothamBlack
		nLbl.TextScaled = false
		nLbl.TextSize = 15
		nLbl.TextXAlignment = Enum.TextXAlignment.Center
		nLbl.TextYAlignment = Enum.TextYAlignment.Center
		nLbl.TextStrokeTransparency = 0.38
		nLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

		local sLbl = Instance.new("TextLabel", box)
		sLbl.Size = UDim2.new(1, -10, 0, 11)
		sLbl.Position = UDim2.new(0, 5, 0, 19)
		sLbl.BackgroundTransparency = 1
		sLbl.Text = player.Name
		sLbl.TextColor3 = ESP_SUBTEXT
		sLbl.Font = Enum.Font.GothamBold
		sLbl.TextScaled = false
		sLbl.TextSize = 10
		sLbl.TextXAlignment = Enum.TextXAlignment.Center
		sLbl.TextYAlignment = Enum.TextYAlignment.Center
		sLbl.TextStrokeTransparency = 0.58
		sLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

		local BASE_W, BASE_H = 124, 34
		local MIN_W, MIN_H = 78, 22
		local NEAR_DIST, FAR_DIST = 35, 140

		local speedConn = RunService.Heartbeat:Connect(function()
			if not PlayerESP.enabled or not hrp or not hrp.Parent then return end

			local v = hrp.AssemblyLinearVelocity or hrp.Velocity
			local mag = Vector3.new(v.X, 0, v.Z).Magnitude
			nLbl.Text = string.format("%d speed", math.floor(mag + 0.5))
			sLbl.Text = player.Name

			local cam = workspace.CurrentCamera
			if cam then
				local dist = (cam.CFrame.Position - hrp.Position).Magnitude
				local t = math.clamp((dist - NEAR_DIST) / (FAR_DIST - NEAR_DIST), 0, 1)
				local scale = 1 - (0.37 * t)

				bb.Size = UDim2.new(0, math.max(MIN_W, math.floor(BASE_W * scale)), 0, math.max(MIN_H, math.floor(BASE_H * scale)))
				nLbl.TextSize = math.max(10, math.floor(15 * scale))
				sLbl.TextSize = math.max(7, math.floor(10 * scale))
			end
		end)

		PlayerESP.playerData[player] = {
			highlight = hl,
			billboard = bb,
			nameLabel = nLbl,
			speedLabel = sLbl,
			conns = {speedConn},
		}
	end

	local function _espOnPlayerAdded(player)
		if not PlayerESP.enabled or player == LP then return end
		local function onChar(char)
			task.spawn(function() _espSetupCharacter(player, char) end)
		end
		if player.Character then onChar(player.Character) end
		table.insert(PlayerESP.conns, player.CharacterAdded:Connect(onChar))
	end

	startPlayerESP = function()
		if PlayerESP.enabled then return end
		PlayerESP.enabled = true
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then _espOnPlayerAdded(p) end
		end
		table.insert(PlayerESP.conns, Players.PlayerAdded:Connect(_espOnPlayerAdded))
		table.insert(PlayerESP.conns, Players.PlayerRemoving:Connect(_espCleanupPlayer))
	end

	stopPlayerESP = function()
		if not PlayerESP.enabled then return end
		PlayerESP.enabled = false
		for _, c in ipairs(PlayerESP.conns) do pcall(function() c:Disconnect() end) end
		PlayerESP.conns = {}
		for player, _ in pairs(PlayerESP.playerData) do _espCleanupPlayer(player) end
	end
end
holdJumpPressed = false
holdJumpActive = false
function applyInfJumpBoost(boost)
	if not infJumpEnabled then return end
	local char=LP.Character;if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	if root then root.Velocity=Vector3.new(root.Velocity.X,boost,root.Velocity.Z) end
end
UIS.JumpRequest:Connect(function() applyInfJumpBoost(50) end)
UIS.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space and not UIS:GetFocusedTextBox() then
		holdJumpPressed=true
		task.delay(0.12,function()
			if holdJumpPressed then
				holdJumpActive=true
				applyInfJumpBoost(50)
			end
		end)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space then holdJumpPressed=false;holdJumpActive=false end
end)
RunService.Heartbeat:Connect(function()
	if holdJumpActive then applyInfJumpBoost(50) end
end)
function startUnwalk()
	local c=LP.Character;if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid")
	if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
	local anim=c:FindFirstChild("Animate")
	if anim then unwalkSavedAnimate=anim:Clone();anim:Destroy() end
end
function stopUnwalk()
	local c=LP.Character
	if c and unwalkSavedAnimate then unwalkSavedAnimate:Clone().Parent=c;unwalkSavedAnimate=nil end
end
-- ============================================================
-- DROP BRAINROT - ported from AdaptHub (ascend 0.2s, raycast down, snap to floor)
-- More reliable than the old fling-burst implementation
-- ============================================================
DROP_ASCEND_DURATION, DROP_ASCEND_SPEED = 0.2, 150
function runDrop()
	if dropActive then return end
	if autoBatEnabled then
		autoBatEnabled=false
		if resetAutoBatMotion then resetAutoBatMotion() end
		if autoBatSetVisual then autoBatSetVisual(false) end
	end
	local char = LP.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	dropActive = true
	local t0 = tick()
	local dc
	dc = RunService.Heartbeat:Connect(function()
		local r = char and char:FindFirstChild("HumanoidRootPart")
		if not r then
			dc:Disconnect()
			dropActive = false
			return
		end
		if tick() - t0 >= DROP_ASCEND_DURATION then
			dc:Disconnect()
			local rp = RaycastParams.new()
			rp.FilterDescendantsInstances = {char}
			rp.FilterType = Enum.RaycastFilterType.Exclude
			local rr = workspace:Raycast(r.Position, Vector3.new(0, -2000, 0), rp)
			if rr then
				local hum2 = char:FindFirstChildOfClass("Humanoid")
				local off = (hum2 and hum2.HipHeight or 2) + (r.Size.Y / 2)
				r.CFrame = CFrame.new(r.Position.X, rr.Position.Y + off, r.Position.Z)
				r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			end
			dropActive = false
			return
		end
		r.Velocity = Vector3.new(r.Velocity.X, DROP_ASCEND_SPEED, r.Velocity.Z)
	end)
end
function doAutoTPDown(force)
	local char=LP.Character;if not char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end
	local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
	if not force then
		if hum2.FloorMaterial~=Enum.Material.Air then return end
		if hrp.Position.Y<autoTPHeight then return end
	end
	hrp.CFrame=CFrame.new(hrp.Position.X,-7.00,hrp.Position.Z)
		*CFrame.Angles(0,select(2,hrp.CFrame:ToEulerAnglesYXZ()),0)
	hrp.AssemblyLinearVelocity=Vector3.zero
end
function startAutoTP()
	if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
	autoTPConn=task.spawn(function()
		while autoTPEnabled do
			task.wait(0.1)
			pcall(function() doAutoTPDown(false) end)
		end
	end)
end
function stopAutoTP()
	autoTPEnabled=false
	if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
end
function runTPFloor()
	pcall(function() doAutoTPDown(true) end)
end
defLightBrightness,defLightClock,defLightAmbient = nil, nil, nil
function enableStretchRez()
	stretchRezEnabled=true
	if not V.customFovEnabled then
		workspace.CurrentCamera.FieldOfView=107
	end
	if stretchRezConn then stretchRezConn:Disconnect() end
	stretchRezConn=RunService.RenderStepped:Connect(function()
		if not stretchRezEnabled then stretchRezConn:Disconnect();stretchRezConn=nil;return end
		if not V.customFovEnabled then
			workspace.CurrentCamera.FieldOfView=107
		end
	end)
end
function disableStretchRez()
	stretchRezEnabled=false
	if stretchRezConn then stretchRezConn:Disconnect();stretchRezConn=nil end
	if not V.customFovEnabled then
		workspace.CurrentCamera.FieldOfView=70
	end
end
-- ============================================================
-- CUSTOM FOV - user-adjustable Field of View
-- ============================================================
function enableCustomFov()
	V.customFovEnabled=true
	workspace.CurrentCamera.FieldOfView=V.customFovValue
	if V.customFovConn then V.customFovConn:Disconnect() end
	V.customFovConn=RunService.RenderStepped:Connect(function()
		if not V.customFovEnabled then V.customFovConn:Disconnect();V.customFovConn=nil;return end
		workspace.CurrentCamera.FieldOfView=V.customFovValue
	end)
end
function disableCustomFov()
	V.customFovEnabled=false
	if V.customFovConn then V.customFovConn:Disconnect();V.customFovConn=nil end
	if stretchRezEnabled then
		workspace.CurrentCamera.FieldOfView=107
	else
		workspace.CurrentCamera.FieldOfView=70
	end
end
antiLagDefBrightness, antiLagDefFog, antiLagDefDiffuse, antiLagDefSpecular = nil, nil, nil, nil

function _applyAntiLagObj(obj)
	pcall(function()
		if obj:IsA("BasePart") then
			obj.Material = Enum.Material.Plastic
			obj.Reflectance = 0
			obj.CastShadow = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
			or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
			obj.Enabled = false
		elseif obj:IsA("AnimationController") or obj:IsA("Animator") then
			for _, t in ipairs(obj:GetPlayingAnimationTracks()) do
				pcall(function() t:Stop(0) end)
			end
		end
	end)
end

function processAntiLagDescendant(obj)
	if antiLagEnabled or V.ultraModeEnabled then
		_applyAntiLagObj(obj)
	end
	if removeAccessoriesEnabled or V.removeAccessoriesEnabledSep then
		pcall(function()
			if obj:IsA("Accessory") or obj:IsA("Hat") then
				obj:Destroy()
			end
		end)
	end
end

function applyKTMOptimization()
	-- Backwards-compatible alias used by Ultra Mode.
	antiLagDefBrightness = antiLagDefBrightness or Lighting.Brightness
	antiLagDefFog = antiLagDefFog or Lighting.FogEnd
	antiLagDefDiffuse = antiLagDefDiffuse or Lighting.EnvironmentDiffuseScale
	antiLagDefSpecular = antiLagDefSpecular or Lighting.EnvironmentSpecularScale

	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1e10
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
	end)

	for _, e in pairs(Lighting:GetChildren()) do
		pcall(function()
			if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or
				e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or
				e:IsA("DepthOfFieldEffect") then
				e.Enabled = false
			end
		end)
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		_applyAntiLagObj(obj)
	end

	if antiLagDescConn then antiLagDescConn:Disconnect() end
	antiLagDescConn = Workspace.DescendantAdded:Connect(function(obj)
		if antiLagEnabled or V.ultraModeEnabled or removeAccessoriesEnabled or V.removeAccessoriesEnabledSep then
			processAntiLagDescendant(obj)
		end
	end)
end

function enableAntiLag()
	if antiLagEnabled then return end
	antiLagEnabled = true
	applyKTMOptimization()
end

function disableAntiLag()
	antiLagEnabled = false
	if antiLagDescConn and not V.ultraModeEnabled and not removeAccessoriesEnabled and not V.removeAccessoriesEnabledSep then
		antiLagDescConn:Disconnect()
		antiLagDescConn = nil
	end

	pcall(function()
		Lighting.GlobalShadows = true
		if antiLagDefBrightness then Lighting.Brightness = antiLagDefBrightness end
		if antiLagDefFog then Lighting.FogEnd = antiLagDefFog end
		if antiLagDefDiffuse then Lighting.EnvironmentDiffuseScale = antiLagDefDiffuse end
		if antiLagDefSpecular then Lighting.EnvironmentSpecularScale = antiLagDefSpecular end

		for _, e in pairs(Lighting:GetChildren()) do
			pcall(function()
				if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or
					e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or
					e:IsA("DepthOfFieldEffect") then
					e.Enabled = true
				end
			end)
		end
	end)
end
function removeAllAccessories()
	for _,player in pairs(Players:GetPlayers()) do
		if player.Character then
			for _,obj in ipairs(player.Character:GetDescendants()) do
				if obj:IsA("Accessory") or obj:IsA("Hat") then
					pcall(function() obj:Destroy() end)
				end
			end
		end
	end
end

function enableRemoveAccessories()
	V.removeAccessoriesEnabledSep = true
	removeAccessoriesEnabled = true
	removeAllAccessories()
	if V.removeAccConn then V.removeAccConn:Disconnect() end
	V.removeAccConn = Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(0.5)
			if V.removeAccessoriesEnabledSep or removeAccessoriesEnabled then
				for _,obj in ipairs(char:GetDescendants()) do processAntiLagDescendant(obj) end
			end
		end)
	end)
	if antiLagDescConn then antiLagDescConn:Disconnect() end
	antiLagDescConn = Workspace.DescendantAdded:Connect(function(obj)
		if antiLagEnabled or V.ultraModeEnabled or removeAccessoriesEnabled or V.removeAccessoriesEnabledSep then
			processAntiLagDescendant(obj)
		end
	end)
end

function disableRemoveAccessories()
	V.removeAccessoriesEnabledSep = false
	removeAccessoriesEnabled = false
	if V.removeAccConn then
		V.removeAccConn:Disconnect()
		V.removeAccConn = nil
	end
	if antiLagDescConn then
		antiLagDescConn:Disconnect()
		antiLagDescConn = nil
	end
end

function findMedusa()
	local c=LP.Character;if not c then return nil end
	for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
	local bp=LP:FindFirstChild("Backpack")
	if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end
	return nil
end
function useMedusaCounter()
	if medusaDebounce then return end;if tick()-medusaLastUsed<MEDUSA_COOLDOWN then return end
	local c=LP.Character;if not c then return end;medusaDebounce=true
	local med=findMedusa();if not med then medusaDebounce=false;return end
	if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid");if hum2 then hum2:EquipTool(med) end end
	pcall(function() med:Activate() end);medusaLastUsed=tick();medusaDebounce=false
end
function onAnchorChanged(part)
	return part:GetPropertyChangedSignal("Anchored"):Connect(function()
		if part.Anchored and part.Transparency==1 then useMedusaCounter() end
	end)
end
function setupMedusa(char)
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
	if not char then return end
	for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
	table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
	end))
end
function stopMedusaCounter()
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
end

autoResetMedTriggered = false
autoResetLastFire = 0
AUTO_RESET_MED_COOLDOWN = 2.25

function _autoResetShouldFire(part)
	if not autoResetEnabled then return false end
	if autoResetMedTriggered then return false end
	if tick() - autoResetLastFire < AUTO_RESET_MED_COOLDOWN then return false end
	if not part or not part.Parent then return false end
	return part.Anchored and part.Transparency == 1
end

function _autoResetFireOnce(part)
	if not _autoResetShouldFire(part) then return end
	autoResetMedTriggered = true
	autoResetLastFire = tick()
	cursedInstaReset()
end

function _autoResetOnAnchorChanged(part)
	return part:GetPropertyChangedSignal("Anchored"):Connect(function()
		_autoResetFireOnce(part)
	end)
end

function startAutoReset(char)
	for _,c in ipairs(autoResetConns) do pcall(function() c:Disconnect() end) end
	autoResetConns = {}
	autoResetMedTriggered = false
	if not char then return end
	for _,part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(autoResetConns,_autoResetOnAnchorChanged(part))
			_autoResetFireOnce(part)
		end
	end
	table.insert(autoResetConns,char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then
			table.insert(autoResetConns,_autoResetOnAnchorChanged(part))
			_autoResetFireOnce(part)
		end
	end))
	table.insert(autoResetConns,char.AncestryChanged:Connect(function(_,parent)
		if not parent then autoResetMedTriggered = false end
	end))
end

function stopAutoReset()
	for _,c in ipairs(autoResetConns) do pcall(function() c:Disconnect() end) end
	autoResetConns = {}
	autoResetMedTriggered = false
end

_antiDesyncHittingCooldown=false

function antiDesyncGetBat()
	local char=LP.Character
	if not char then return nil end
	local tool=char:FindFirstChild("Bat")
	if tool then return tool end
	local bp2=LP:FindFirstChild("Backpack")
	if bp2 then
		tool=bp2:FindFirstChild("Bat")
		if tool then tool.Parent=char;return tool end
	end
	return nil
end

function antiDesyncTryHitBat()
	if _antiDesyncHittingCooldown then return end
	_antiDesyncHittingCooldown=true
	pcall(function()
		local bat=antiDesyncGetBat()
		if bat then
			bat:Activate()
			local ev=bat:FindFirstChildWhichIsA("RemoteEvent")
			if ev then ev:FireServer() end
		end
	end)
	task.delay(0.08,function() _antiDesyncHittingCooldown=false end)
end

function antiDesyncGetClosestPlayer(root)
	if not root then return nil,math.huge end
	local cp,cd=nil,math.huge
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			local tr=p.Character:FindFirstChild("HumanoidRootPart")
			if tr then
				local d=(root.Position-tr.Position).Magnitude
				if d<cd then cd=d;cp=p end
			end
		end
	end
	return cp,cd
end

startAntiDesyncAutoBat=function()
	if Conns.antiDesyncAutoBat then Conns.antiDesyncAutoBat:Disconnect();Conns.antiDesyncAutoBat=nil end

	antiDesyncAutoBatEnabled=true
	if setAntiDesyncAutoBatVisual then setAntiDesyncAutoBatVisual(true) end

	Conns.antiDesyncAutoBat=RunService.Heartbeat:Connect(function()
		if not antiDesyncAutoBatEnabled then return end
		local char=LP.Character
		if not char then return end
		local hum=char:FindFirstChildOfClass("Humanoid")
		local root=char:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return end
		local target=antiDesyncGetClosestPlayer(root)
		if target and target.Character then
			local tr=target.Character:FindFirstChild("HumanoidRootPart")
			if tr then
				if sethiddenproperty then
					sethiddenproperty(root,"PhysicsRepRootPart",tr)
				end
				local targetPos=tr.Position+Vector3.new(0,0.9,0)
				if (root.Position-targetPos).Magnitude>8 then
					root.CFrame=CFrame.new(targetPos)
				end
				local cam=workspace.CurrentCamera
				cam.CFrame=CFrame.new(cam.CFrame.Position,tr.Position)
				antiDesyncTryHitBat()
			end
		end
	end)
end

stopAntiDesyncAutoBat=function()
	if Conns.antiDesyncAutoBat then Conns.antiDesyncAutoBat:Disconnect();Conns.antiDesyncAutoBat=nil end
	antiDesyncAutoBatEnabled=false
	_antiDesyncHittingCooldown=false
	if setAntiDesyncAutoBatVisual then setAntiDesyncAutoBatVisual(false) end
end

function enableNoCamCollision()
	noCamCollisionEnabled = true
	if noCamCollisionConn then noCamCollisionConn:Disconnect() end
	noCamCollisionConn = RunService.RenderStepped:Connect(function()
		if not noCamCollisionEnabled then
			if noCamCollisionConn then noCamCollisionConn:Disconnect();noCamCollisionConn=nil end
			return
		end
		local cam = workspace.CurrentCamera
		local char = LP.Character
		if not cam or not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local camPos = cam.CFrame.Position
		local charPos = hrp.Position + Vector3.new(0,1.5,0)
		local toChar = charPos - camPos
		if toChar.Magnitude < 0.3 then return end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {char}
		params.IgnoreWater = true
		local hit = {}
		local origin = camPos
		local remaining = toChar
		for _ = 1,12 do
			if remaining.Magnitude < 0.2 then break end
			local res = workspace:Raycast(origin,remaining,params)
			if not res then break end
			local part = res.Instance
			if part and part:IsA("BasePart") and not part:IsDescendantOf(char) then
				hit[part] = true
				if noCamCollisionParts[part] == nil then noCamCollisionParts[part] = part.LocalTransparencyModifier end
				part.LocalTransparencyModifier = 1
			end
			origin = res.Position + remaining.Unit * 0.02
			remaining = charPos - origin
		end
		for part,orig in pairs(noCamCollisionParts) do
			if not hit[part] then
				pcall(function() if part and part.Parent then part.LocalTransparencyModifier = orig end end)
				noCamCollisionParts[part] = nil
			end
		end
	end)
end

function disableNoCamCollision()
	noCamCollisionEnabled = false
	if noCamCollisionConn then noCamCollisionConn:Disconnect();noCamCollisionConn=nil end
	for part,orig in pairs(noCamCollisionParts) do
		pcall(function() if part and part.Parent then part.LocalTransparencyModifier = orig end end)
	end
	noCamCollisionParts = {}
end

HIT_HARDER_ANIMS = {
	idle1 = "rbxassetid://133806214992291",
	idle2 = "rbxassetid://94970088341563",
	walk = "rbxassetid://707897309",
	run = "rbxassetid://707861613",
	jump = "rbxassetid://116936326516985",
	fall = "rbxassetid://116936326516985",
}

function _hitHarderSaveOriginals(char)
	local animate = char:FindFirstChild("Animate")
	if not animate then return end
	local function g(obj) return obj and obj.AnimationId or nil end
	hitHarderOriginalAnims = {
		idle1 = g(animate.idle and animate.idle:FindFirstChild("Animation1")),
		idle2 = g(animate.idle and animate.idle:FindFirstChild("Animation2")),
		walk = g(animate.walk and animate.walk:FindFirstChild("WalkAnim")),
		run = g(animate.run and animate.run:FindFirstChild("RunAnim")),
		jump = g(animate.jump and animate.jump:FindFirstChild("JumpAnim")),
		fall = g(animate.fall and animate.fall:FindFirstChild("FallAnim")),
	}
end

function _hitHarderApply(char)
	local animate = char:FindFirstChild("Animate")
	if not animate then return end
	local function s(obj,id) if obj and id then pcall(function() obj.AnimationId = id end) end end
	s(animate.idle and animate.idle:FindFirstChild("Animation1"),HIT_HARDER_ANIMS.idle1)
	s(animate.idle and animate.idle:FindFirstChild("Animation2"),HIT_HARDER_ANIMS.idle2)
	s(animate.walk and animate.walk:FindFirstChild("WalkAnim"),HIT_HARDER_ANIMS.walk)
	s(animate.run and animate.run:FindFirstChild("RunAnim"),HIT_HARDER_ANIMS.run)
	s(animate.jump and animate.jump:FindFirstChild("JumpAnim"),HIT_HARDER_ANIMS.jump)
	s(animate.fall and animate.fall:FindFirstChild("FallAnim"),HIT_HARDER_ANIMS.fall)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then for _,track in ipairs(hum:GetPlayingAnimationTracks()) do pcall(function() track:Stop(0) end) end end
end

function _hitHarderRestore(char)
	local animate = char:FindFirstChild("Animate")
	if not animate or not hitHarderOriginalAnims then return end
	local function s(obj,id) if obj and id then pcall(function() obj.AnimationId = id end) end end
	s(animate.idle and animate.idle:FindFirstChild("Animation1"),hitHarderOriginalAnims.idle1)
	s(animate.idle and animate.idle:FindFirstChild("Animation2"),hitHarderOriginalAnims.idle2)
	s(animate.walk and animate.walk:FindFirstChild("WalkAnim"),hitHarderOriginalAnims.walk)
	s(animate.run and animate.run:FindFirstChild("RunAnim"),hitHarderOriginalAnims.run)
	s(animate.jump and animate.jump:FindFirstChild("JumpAnim"),hitHarderOriginalAnims.jump)
	s(animate.fall and animate.fall:FindFirstChild("FallAnim"),hitHarderOriginalAnims.fall)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then for _,track in ipairs(hum:GetPlayingAnimationTracks()) do pcall(function() track:Stop(0) end) end end
end

function enableHitHarderAnim()
	hitHarderAnimEnabled = true
	local char = LP.Character
	if char then _hitHarderSaveOriginals(char);_hitHarderApply(char) end
	if hitHarderAnimConn then hitHarderAnimConn:Disconnect() end
	hitHarderAnimConn = LP.CharacterAdded:Connect(function(char)
		if not hitHarderAnimEnabled then return end
		task.wait(0.4)
		_hitHarderSaveOriginals(char)
		_hitHarderApply(char)
	end)
end

function disableHitHarderAnim()
	hitHarderAnimEnabled = false
	if hitHarderAnimConn then hitHarderAnimConn:Disconnect();hitHarderAnimConn=nil end
	local char = LP.Character
	if char then _hitHarderRestore(char) end
	hitHarderOriginalAnims = {}
end

BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
function findBatForCounter()
	local c=LP.Character;if not c then return nil end
	local bp=LP:FindFirstChildOfClass("Backpack")
	for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
		local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name));if t then return t end
	end
	for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
	if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
	return nil
end
function swingBatForCounter(bat,char)
	local hum2=char:FindFirstChildOfClass("Humanoid")
	if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end;task.wait(0.05) end
	local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
	if remote and remote:IsA("RemoteEvent") then
		pcall(function() remote:FireServer() end);task.wait(0.15);pcall(function() remote:FireServer() end)
	else pcall(function() bat:Activate() end);task.wait(0.15);pcall(function() bat:Activate() end) end
end
startBatCounter=function()
	if Conns.batCounter then return end
	Conns.batCounter=RunService.Heartbeat:Connect(function()
		if not batCounterEnabled then return end
		if batCounterDebounce then return end
		local char=LP.Character;if not char then return end
		local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
		local st=hum2:GetState()
		if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
			batCounterDebounce=true
			task.spawn(function()
				local bat=findBatForCounter()
				if bat then swingBatForCounter(bat,char) end
				task.wait(0.5);batCounterDebounce=false
			end)
		end
	end)
end
stopBatCounter=function()
	if Conns.batCounter then Conns.batCounter:Disconnect();Conns.batCounter=nil end
	batCounterDebounce=false
end

-- ============================================================
-- HIT / RAGDOLL COUNTDOWN
-- ============================================================
RAGDOLL_COUNTDOWN = 2.6
ragdollCountdownEnabled = false
_ragdollTimerActive = false
_ragdollTimerThread = nil
ragdollCountdownFrame = ragdollCountdownFrame or nil
ragdollCountdownLabel = ragdollCountdownLabel or nil
_ragdollHookedHumanoids = {}

function stopRagdollCountdown()
	if _ragdollTimerThread then
		task.cancel(_ragdollTimerThread)
		_ragdollTimerThread = nil
	end
	_ragdollTimerActive = false
	if ragdollCountdownFrame then ragdollCountdownFrame.Visible = false end
	if ragdollCountdownLabel then
		ragdollCountdownLabel.Visible = false
		ragdollCountdownLabel.Text = ""
	end
end

function startRagdollCountdown()
	if not ragdollCountdownEnabled then return end
	if _ragdollTimerActive then return end
	if not ragdollCountdownLabel then return end

	_ragdollTimerActive = true
	if ragdollCountdownFrame then ragdollCountdownFrame.Visible = true end
	ragdollCountdownLabel.Visible = true

	if _ragdollTimerThread then
		task.cancel(_ragdollTimerThread)
		_ragdollTimerThread = nil
	end

	_ragdollTimerThread = task.spawn(function()
		local startT = tick()

		while ragdollCountdownFrame and ragdollCountdownFrame.Parent do
			local elapsed = tick() - startT
			local remaining = RAGDOLL_COUNTDOWN - elapsed

			if remaining <= 0 then break end

			if ragdollCountdownLabel then
				ragdollCountdownLabel.Text = string.format("%.1f", remaining)
				if remaining > 2 then
					ragdollCountdownLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
				elseif remaining > 1 then
					ragdollCountdownLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
				else
					ragdollCountdownLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
				end
			end

			task.wait(0.05)
		end

		if ragdollCountdownLabel then
			ragdollCountdownLabel.Text = "Ready to Steal"
			ragdollCountdownLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
		end

		task.wait(3)

		if ragdollCountdownFrame then ragdollCountdownFrame.Visible = false end
		if ragdollCountdownLabel then ragdollCountdownLabel.Visible = false end
		_ragdollTimerActive = false
		_ragdollTimerThread = nil
	end)
end

function hookRagdollCountdown(char)
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
	if not hum or _ragdollHookedHumanoids[hum] then return end
	_ragdollHookedHumanoids[hum] = true

	hum.StateChanged:Connect(function(_old, new)
		if not ragdollCountdownEnabled then return end

		if new == Enum.HumanoidStateType.Physics
		or new == Enum.HumanoidStateType.Ragdoll
		or new == Enum.HumanoidStateType.FallingDown then
			startRagdollCountdown()
		end
	end)
end

-- ============================================================
-- CANDY AIMBOT / AUTO SWING / TARGET LOCK PORT
-- Replaces the old float-beside target aimbot with Candy's chase + predicted lock logic.
-- ============================================================
_aimbotTarget = nil
_aimbotTargetPlr = nil
_aimbotHumanoid = nil
_prevAutoRotate = nil
_hittingCooldown = false
BAT_SLAP_LIST={
	"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap",
	"Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap",
	"Galaxy Slap","Glitched Slap"
}
AIMBOT_HIT_DIST=8
AIMBOT_SWING_CD=0.35
startBatAimbot, stopBatAimbot = nil, nil

function getBatAimbotChaseSpeed()
	if laggerToggled then return aimbotLaggerSpeed end
	return aimbotSpeed
end


resetAutoBatMotion=function()
	local char=LP.Character
	local hrp=char and char:FindFirstChild("HumanoidRootPart")
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if _aimbotHumanoid and _aimbotHumanoid.Parent then
		_aimbotHumanoid.AutoRotate=(_prevAutoRotate==nil) and true or _prevAutoRotate
		_aimbotHumanoid.PlatformStand=false
		pcall(function() _aimbotHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	elseif hum then
		hum.AutoRotate=(_prevAutoRotate==nil) and true or _prevAutoRotate
		hum.PlatformStand=false
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	end
	if hrp then
		hrp.AssemblyLinearVelocity=Vector3.new(0,hrp.AssemblyLinearVelocity.Y*0.3,0)
		hrp.AssemblyAngularVelocity=Vector3.zero
	end
	_aimbotHumanoid=nil
	_prevAutoRotate=nil
end

function findBat()
	local char=LP.Character
	if not char then return nil end
	for _,name in ipairs(BAT_SLAP_LIST) do
		local tool=char:FindFirstChild(name)
		if tool and tool:IsA("Tool") then return tool end
	end
	local bp=LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
	if bp then
		for _,name in ipairs(BAT_SLAP_LIST) do
			local tool=bp:FindFirstChild(name)
			if tool and tool:IsA("Tool") then
				local hum=char:FindFirstChildOfClass("Humanoid")
				if hum then pcall(function() hum:EquipTool(tool) end) end
				return tool
			end
		end
	end
	for _,tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
	end
	if bp then
		for _,tool in ipairs(bp:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
				local hum=char:FindFirstChildOfClass("Humanoid")
				if hum then pcall(function() hum:EquipTool(tool) end) end
				return tool
			end
		end
	end
	return nil
end

function getClosestTarget()
	local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil,nil,math.huge end
	local closest,closestPlr,minDist=nil,nil,math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LP and plr.Character then
			local tRoot=plr.Character:FindFirstChild("HumanoidRootPart")
			local hum=plr.Character:FindFirstChildOfClass("Humanoid")
			if tRoot and hum and hum.Health>0 then
				local dist=(tRoot.Position-root.Position).Magnitude
				if dist<minDist then minDist=dist;closest=tRoot;closestPlr=plr end
			end
		end
	end
	return closest,closestPlr,minDist
end

function tryAimbotSwing()
	if _hittingCooldown or not autoSwingEnabled then return end
	_hittingCooldown=true
	pcall(function()
		local char=LP.Character
		if not char then return end
		local bat=findBat()
		if not bat then return end
		if bat.Parent~=char then
			local hum=char:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(bat) end) end
		end
		pcall(function() bat:Activate() end)
	end)
	task.delay(AIMBOT_SWING_CD,function() _hittingCooldown=false end)
end

startBatAimbot=function()
	if Conns.aimbot then Conns.aimbot:Disconnect() end
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	if autoTPEnabled then stopAutoTP();if setAutoTPVisual then setAutoTPVisual(false) end end

	autoBatEnabled=true
	local hum0=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum0 then
		_aimbotHumanoid=hum0
		_prevAutoRotate=hum0.AutoRotate
		hum0.AutoRotate=false
	end

	Conns.aimbot=RunService.RenderStepped:Connect(function()
		if not autoBatEnabled then return end
		local char=LP.Character;if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
		local hum=char:FindFirstChildOfClass("Humanoid");if not hum then return end
		if hum~=_aimbotHumanoid then
			_aimbotHumanoid=hum
			_prevAutoRotate=hum.AutoRotate
		end
		hum.AutoRotate=false

		if not char:FindFirstChildOfClass("Tool") then
			local bat=findBat()
			if bat then pcall(function() hum:EquipTool(bat) end) end
		end

		local target,targetPlr,targetDist=getClosestTarget()
		if not target then
			_aimbotTarget=nil;_aimbotTargetPlr=nil
			return
		end
		_aimbotTarget=target
		_aimbotTargetPlr=targetPlr
		local targetVel=target.AssemblyLinearVelocity
		local myPos=root.Position
		local targetPos=target.Position
		local predictPos=targetPos+targetVel*0.14+target.CFrame.LookVector*0.3
		local direction=predictPos-myPos
		local flatDir=Vector3.new(direction.X,0,direction.Z)
		if flatDir.Magnitude>0 then flatDir=flatDir.Unit else flatDir=Vector3.new(0,0,0) end
		local chaseSpeed=getBatAimbotChaseSpeed()
		local desiredHeight=targetPos.Y+3.7
		local yVel=(desiredHeight-myPos.Y)*19.5+targetVel.Y*0.8
		if hum.FloorMaterial~=Enum.Material.Air then yVel=math.max(yVel,13) end
		yVel=math.clamp(yVel,-70,110)
		local desiredVel=Vector3.new(flatDir.X*chaseSpeed,yVel,flatDir.Z*chaseSpeed)
		root.AssemblyLinearVelocity=root.AssemblyLinearVelocity:Lerp(desiredVel,0.8)
		local predictTime=math.clamp(targetVel.Magnitude/150,0.05,0.2)
		local predictedPos=targetPos+targetVel*predictTime
		local toPredict=predictedPos-myPos
		if toPredict.Magnitude>0.1 then
			local goalCF=CFrame.lookAt(myPos,predictedPos)
			local diffCF=root.CFrame:Inverse()*goalCF
			local rx,ry,rz=diffCF:ToEulerAnglesXYZ()
			rx=math.clamp(rx,-2.5,2.5); ry=math.clamp(ry,-2.5,2.5); rz=math.clamp(rz,-2.5,2.5)
			root.AssemblyAngularVelocity=root.CFrame:VectorToWorldSpace(Vector3.new(rx*42,ry*42,rz*42))
		end
		if autoSwingEnabled and targetDist<=AIMBOT_HIT_DIST then tryAimbotSwing() end
	end)
end

stopBatAimbot=function()
	if Conns.aimbot then Conns.aimbot:Disconnect();Conns.aimbot=nil end
	_aimbotTarget=nil
	_aimbotTargetPlr=nil
	autoBatEnabled=false
	_hittingCooldown=false
	if resetAutoBatMotion then resetAutoBatMotion() end
end

-- ============================================================
-- ACE ANTI KICK LOCK
-- Blocks Auto Left / Auto Right / Bat Aimbot only while risky:
-- 1) duel countdown is active, or 2) player is holding/stealing a brainrot.
-- ============================================================
function _akCountdownNumber(text)
	local n = tonumber(text)
	return n ~= nil and n >= 1 and n <= 5
end

function _akGetCountdownLabel()
	local ok,label = pcall(function()
		return LP.PlayerGui
			and LP.PlayerGui:FindFirstChild("DuelsMachineTopFrame")
			and LP.PlayerGui.DuelsMachineTopFrame:FindFirstChild("DuelsMachineTopFrame")
			and LP.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame:FindFirstChild("Timer")
			and LP.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer:FindFirstChild("Label")
	end)
	return (ok and label) or nil
end

function _akInDuelCountdown()
	local label = _akGetCountdownLabel()
	return label and _akCountdownNumber(label.Text) or false
end

_akBlockedTools = {
	bat=true, slap=true, sword=true, gun=true, pistol=true, rifle=true,
	medusa=true, hammer=true, axe=true, knife=true, katana=true, blade=true, fist=true,
}

function _akIsCarryableTool(tool)
	if not tool or not tool:IsA("Tool") then return false end
	local name = tool.Name:lower()
	for word in pairs(_akBlockedTools) do
		if name:find(word,1,true) then return false end
	end
	return true
end

function _akHoldingBrainrot()
	local ok,val = pcall(function() return LP:GetAttribute("Stealing") end)
	if ok and val == true then return true end
	local ok2,val2 = pcall(function() return LP:GetAttribute("AntiKick") end)
	if ok2 and val2 == true then return true end
	local ok3,val3 = pcall(function() return LP:GetAttribute("Locked") end)
	if ok3 and val3 == true then return true end
	local char = LP.Character
	if not char then return false end
	local ok4,val4 = pcall(function() return char:GetAttribute("Stealing") end)
	if ok4 and val4 == true then return true end
	for _,child in ipairs(char:GetChildren()) do
		if _akIsCarryableTool(child) then return true end
	end
	return false
end

function _akIsLocked()
	if not antiKickEnabled then return false end
	return _akInDuelCountdown() or _akHoldingBrainrot()
end

function _akForceStop(reason)
	local stopped = false
	if autoBatEnabled then
		stopBatAimbot()
		if autoBatSetVisual then autoBatSetVisual(false) end
		stopped = true
	end
	if autoLeftEnabled then
		autoLeftEnabled = false
		if alConn then alConn:Disconnect(); alConn = nil end
		local char = LP.Character
		if char then local h = char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
		if autoLeftSetVisual then autoLeftSetVisual(false) end
		stopped = true
	end
	if autoRightEnabled then
		autoRightEnabled = false
		if arConn then arConn:Disconnect(); arConn = nil end
		local char = LP.Character
		if char then local h = char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
		if autoRightSetVisual then autoRightSetVisual(false) end
		stopped = true
	end
	if stopped then _safeNotify(reason or "ANTI KICK LOCK") end
end

function _akTryStart(featureName)
	if _akIsLocked() then
		_akForceStop("ANTI KICK LOCK")
		return false
	end
	return true
end

RunService.Heartbeat:Connect(function()
	if _akIsLocked() and (autoBatEnabled or autoLeftEnabled or autoRightEnabled) then
		_akForceStop("ANTI KICK LOCK")
	end
end)

LP.CharacterAdded:Connect(function()
	task.wait(0.7)
	if _akIsLocked() then _akForceStop("ANTI KICK LOCK") end
end)

function enableAutoBat()
	startBatAimbot()
end
function disableAutoBat()
	stopBatAimbot()
end
function queueAutoLeftStart()
	if not _akTryStart("Auto Left") then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;return end
	autoLeftEnabled=true
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	if autoBatEnabled then stopBatAimbot();if autoBatSetVisual then autoBatSetVisual(false) end end
	startAutoLeft()
end
function queueAutoRightStart()
	if not _akTryStart("Auto Right") then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;return end
	autoRightEnabled=true
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoBatEnabled then stopBatAimbot();if autoBatSetVisual then autoBatSetVisual(false) end end
	startAutoRight()
end
function queueAutoBatStart()
	if not _akTryStart("Aimbot") then autoBatEnabled=false;if autoBatSetVisual then autoBatSetVisual(false) end;return end
	startBatAimbot()
end
LP.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	setupSpeedIndicator(char)
	hookRagdollCountdown(char)
	if medusaCounterEnabled then setupMedusa(char) end
	if autoResetEnabled then startAutoReset(char) end
	if batCounterEnabled then startBatCounter() end
	if autoBatEnabled then task.wait(0.2);resetAutoBatMotion();startBatAimbot() end
	if unwalkEnabled then task.wait(0.5);startUnwalk() end
	if hitHarderAnimEnabled then _hitHarderSaveOriginals(char);_hitHarderApply(char) end
end)
if LP.Character then
	setupSpeedIndicator(LP.Character)
	hookRagdollCountdown(LP.Character)
	if autoResetEnabled then startAutoReset(LP.Character) end
	if hitHarderAnimEnabled then _hitHarderSaveOriginals(LP.Character);_hitHarderApply(LP.Character) end
end
SKY_PRESETS_LIST = {"Off","Night","Aurora","Sunset","Galaxy","Cyber","Sakura","Pink Night",
    "Blood Moon","Emerald Dawn","Volcanic","Arctic","Midnight Ocean","Vaporwave","Toxic","Solar Eclipse",
    "Hellscape","Heaven","Storm","Sunrise","Deep Space","Lavender Dream","Inferno","Mint Sky"}
SKY_PRESETS = {
    ["Off"] = {kind = "off"},
    ["Night"] = {clock=22,brightness=2,ambient={110,100,130},outAmb={120,110,140},sky={stars=4000,moon=18,sun=0,moonTex=true},atm={dens=0.45,color={120,60,180},decay={60,20,100},glare=0.5,haze=1.2}},
    ["Aurora"] = {clock=14,brightness=3,ambient={150,120,150},outAmb={160,130,150},atm={dens=0.55,color={255,80,200},decay={255,20,150},glare=2.5,haze=3},clouds={cover=0.7,dens=0.7,color={255,240,250}}},
    ["Sunset"] = {clock=17.2,brightness=2.5,ambient={170,120,100},outAmb={180,130,110},sky={stars=0,sun=25,moon=0},atm={dens=0.5,color={255,130,60},decay={255,80,30},glare=2,haze=2.5},clouds={cover=0.55,dens=0.55,color={255,200,140}}},
    ["Galaxy"] = {clock=0,brightness=1.5,ambient={70,60,100},outAmb={80,70,110},sky={stars=10000,moon=30,sun=0},atm={dens=0.15,color={40,20,80},decay={20,10,50},glare=0.3,haze=0.5}},
    ["Cyber"] = {clock=21,brightness=2.2,ambient={90,130,170},outAmb={100,140,180},sky={stars=2000,moon=12},atm={dens=0.4,color={0,200,255},decay={150,0,255},glare=2,haze=2},clouds={cover=0.4,dens=0.6,color={100,200,255}}},
    ["Sakura"] = {clock=11,brightness=3.5,ambient={170,150,160},outAmb={180,160,170},sky={sun=8},atm={dens=0.3,color={255,200,220},decay={255,170,200},glare=1,haze=1.5},clouds={cover=0.6,dens=0.4,color={255,250,252}}},
    ["Pink Night"] = {clock=23,brightness=2.2,ambient={120,60,110},outAmb={140,70,120},sky={stars=5000,moon=22,sun=0,moonTex=true},atm={dens=0.5,color={255,80,180},decay={140,30,100},glare=0.7,haze=1.4},clouds={cover=0.3,dens=0.5,color={180,90,150}}},
    ["Blood Moon"] = {clock=22.5,brightness=1.6,ambient={130,40,40},outAmb={150,50,50},sky={stars=1500,moon=28,sun=0,moonTex=true},atm={dens=0.6,color={220,30,30},decay={120,10,10},glare=1.4,haze=2},clouds={cover=0.5,dens=0.7,color={120,30,30}}},
    ["Emerald Dawn"] = {clock=6.5,brightness=2.8,ambient={130,170,140},outAmb={140,180,150},sky={sun=18,moon=0,stars=0},atm={dens=0.4,color={80,200,140},decay={40,150,90},glare=1.8,haze=2.2},clouds={cover=0.5,dens=0.5,color={200,255,220}}},
    ["Volcanic"] = {clock=19,brightness=2,ambient={180,80,40},outAmb={200,90,50},sky={stars=200,sun=12,moon=0},atm={dens=0.75,color={255,60,0},decay={180,20,0},glare=3,haze=3.5},clouds={cover=0.8,dens=0.9,color={120,40,20}}},
    ["Arctic"] = {clock=9,brightness=3.2,ambient={200,220,235},outAmb={210,230,245},sky={sun=10,stars=0,moon=0},atm={dens=0.3,color={180,220,255},decay={140,200,240},glare=1.5,haze=1.8},clouds={cover=0.7,dens=0.6,color={250,253,255}}},
    ["Midnight Ocean"] = {clock=1.5,brightness=1.7,ambient={60,90,130},outAmb={70,100,140},sky={stars=6000,moon=24,sun=0,moonTex=true},atm={dens=0.5,color={20,60,140},decay={10,30,90},glare=0.6,haze=1.5}},
    ["Vaporwave"] = {clock=19.5,brightness=2.4,ambient={180,120,200},outAmb={190,130,210},sky={stars=1000,moon=14},atm={dens=0.45,color={255,100,220},decay={120,60,255},glare=2.2,haze=2.4},clouds={cover=0.5,dens=0.55,color={200,150,255}}},
    ["Toxic"] = {clock=13,brightness=2.5,ambient={140,180,80},outAmb={150,190,90},atm={dens=0.55,color={100,220,40},decay={60,150,20},glare=1.8,haze=2.6},clouds={cover=0.65,dens=0.7,color={180,255,120}}},
    ["Solar Eclipse"] = {clock=12,brightness=0.9,ambient={50,40,60},outAmb={60,50,70},sky={stars=3500,sun=22,moon=0},atm={dens=0.5,color={255,140,40},decay={30,20,40},glare=2.8,haze=1.8}},
    ["Hellscape"] = {clock=18,brightness=1.8,ambient={200,60,30},outAmb={220,70,40},sky={stars=100,sun=30,moon=0},atm={dens=0.85,color={255,30,0},decay={120,0,0},glare=3.5,haze=4},clouds={cover=0.95,dens=0.95,color={80,20,10}}},
    ["Heaven"] = {clock=12,brightness=4,ambient={240,235,210},outAmb={250,245,220},sky={sun=16,moon=0,stars=0},atm={dens=0.25,color={255,250,220},decay={255,240,200},glare=3,haze=1.5},clouds={cover=0.85,dens=0.5,color={255,255,255}}},
    ["Storm"] = {clock=15,brightness=1.4,ambient={90,90,110},outAmb={100,100,120},sky={stars=0,sun=6,moon=0},atm={dens=0.65,color={80,90,120},decay={40,50,80},glare=0.5,haze=3},clouds={cover=0.95,dens=0.95,color={60,65,80}}},
    ["Sunrise"] = {clock=6.2,brightness=2.8,ambient={220,180,130},outAmb={230,190,140},sky={sun=22,stars=0,moon=0},atm={dens=0.45,color={255,180,100},decay={255,140,80},glare=2.4,haze=2.2},clouds={cover=0.4,dens=0.4,color={255,220,180}}},
    ["Deep Space"] = {clock=0,brightness=1,ambient={30,25,50},outAmb={40,35,60},sky={stars=15000,moon=0,sun=0},atm={dens=0.08,color={15,5,40},decay={5,0,20},glare=0.2,haze=0.3}},
    ["Lavender Dream"] = {clock=18.5,brightness=2.6,ambient={180,160,220},outAmb={190,170,230},sky={stars=800,moon=16,sun=0},atm={dens=0.4,color={200,160,255},decay={160,120,220},glare=1.4,haze=1.8},clouds={cover=0.55,dens=0.5,color={220,200,255}}},
    ["Inferno"] = {clock=17.5,brightness=2.2,ambient={220,100,40},outAmb={235,110,50},sky={sun=26,moon=0,stars=0},atm={dens=0.6,color={255,90,20},decay={200,40,0},glare=3,haze=3.2},clouds={cover=0.7,dens=0.7,color={200,80,40}}},
    ["Mint Sky"] = {clock=10,brightness=3.2,ambient={180,230,210},outAmb={190,240,220},sky={sun=10},atm={dens=0.32,color={150,255,210},decay={100,220,180},glare=1.6,haze=1.6},clouds={cover=0.55,dens=0.45,color={240,255,250}}},
}
function _vC3(t) return Color3.fromRGB(t[1], t[2], t[3]) end
function _v4mpClearSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:GetAttribute("_AceDuelsSky") then pcall(function() v:Destroy() end) end
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        for _, v in ipairs(terrain:GetChildren()) do
            if v:GetAttribute("_AceDuelsSky") then pcall(function() v:Destroy() end) end
        end
    end
end
function applyCustomSky(mode)
    _v4mpClearSky()
    local preset = SKY_PRESETS[mode]
    if not preset or preset.kind == "off" then
        Lighting.FogEnd = 100000; Lighting.FogStart = 0
        Lighting.FogColor = Color3.fromRGB(192,192,192)
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = true
        V.skyTheme = "Off"
        return
    end
    Lighting.FogEnd = 100000; Lighting.FogStart = 0
    Lighting.FogColor = Color3.fromRGB(200,200,200)
    Lighting.GlobalShadows = true
    Lighting.ClockTime = preset.clock or 14
    Lighting.Brightness = preset.brightness or 2
    if preset.outAmb then Lighting.OutdoorAmbient = _vC3(preset.outAmb) end
    if preset.ambient then Lighting.Ambient = _vC3(preset.ambient) end
    if preset.sky then
        local sky = Instance.new("Sky")
        sky:SetAttribute("_AceDuelsSky", true)
        if preset.sky.stars then sky.StarCount = preset.sky.stars end
        if preset.sky.moon then sky.MoonAngularSize = preset.sky.moon end
        if preset.sky.sun then sky.SunAngularSize = preset.sky.sun end
        if preset.sky.moonTex then sky.MoonTextureId = "rbxasset://sky/moon.jpg" end
        sky.Parent = Lighting
    end
    if preset.atm then
        local atm = Instance.new("Atmosphere")
        atm:SetAttribute("_AceDuelsSky", true)
        atm.Density = preset.atm.dens or 0.3
        atm.Color = _vC3(preset.atm.color)
        atm.Decay = _vC3(preset.atm.decay)
        atm.Glare = preset.atm.glare or 1
        atm.Haze = preset.atm.haze or 1
        atm.Parent = Lighting
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if preset.clouds and terrain then
        local clouds = Instance.new("Clouds")
        clouds:SetAttribute("_AceDuelsSky", true)
        clouds.Cover = preset.clouds.cover or 0.5
        clouds.Density = preset.clouds.dens or 0.5
        clouds.Color = _vC3(preset.clouds.color)
        clouds.Parent = terrain
    end
    V.skyTheme = mode
end
function enableUltraMode()
    V.ultraModeEnabled = true
    applyKTMOptimization()
end
function disableUltraMode()
    V.ultraModeEnabled = false
end
function enableRemoveAccessories()
	V.removeAccessoriesEnabledSep = true
	removeAccessoriesEnabled = true
	removeAllAccessories()
	if V.removeAccConn then V.removeAccConn:Disconnect() end
	V.removeAccConn = Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(0.5)
			if V.removeAccessoriesEnabledSep or removeAccessoriesEnabled then
				for _,obj in ipairs(char:GetDescendants()) do processAntiLagDescendant(obj) end
			end
		end)
	end)
	if antiLagDescConn then antiLagDescConn:Disconnect() end
	antiLagDescConn = Workspace.DescendantAdded:Connect(function(obj)
		if antiLagEnabled or V.ultraModeEnabled or removeAccessoriesEnabled or V.removeAccessoriesEnabledSep then
			processAntiLagDescendant(obj)
		end
	end)
end
function disableRemoveAccessories()
	V.removeAccessoriesEnabledSep = false
	removeAccessoriesEnabled = false
	if V.removeAccConn then V.removeAccConn:Disconnect(); V.removeAccConn = nil end
	if not antiLagEnabled and not V.ultraModeEnabled and antiLagDescConn then antiLagDescConn:Disconnect(); antiLagDescConn = nil end
end
_v4mpFontMy = nil
_v4mpFontBad = nil
_v4mpFontConn = nil
_v4mpFontOrig = {}
function _v4mpFontTouch(this)
    if this:IsA("TextLabel") or this:IsA("TextButton") or this:IsA("TextBox") then
        if this.TextStrokeTransparency ~= 1 then return false end
        local cur = tostring(this.FontFace)
        return cur == _v4mpFontBad or string.find(cur, "BuilderIcons")
    end
    return true
end
function _v4mpFontChange(txt)
    if (txt:IsA("TextLabel") or txt:IsA("TextButton") or txt:IsA("TextBox")) and not _v4mpFontTouch(txt) then
        if not _v4mpFontOrig[txt] then _v4mpFontOrig[txt] = txt.FontFace end
        pcall(function() txt.FontFace = _v4mpFontMy end)
    end
end
function _v4mpFontSetup()
    -- Removed external font downloading/writefile setup.
    return false
end
function enableCustomFont()
    if V.customFontEnabled then return end
    if not _v4mpFontSetup() then return end
    V.customFontEnabled = true
    for _, v in pairs(game:GetDescendants()) do _v4mpFontChange(v) end
    _v4mpFontConn = game.DescendantAdded:Connect(function(obj)
        if V.customFontEnabled then _v4mpFontChange(obj) end
    end)
end
function disableCustomFont()
    V.customFontEnabled = false
    if _v4mpFontConn then _v4mpFontConn:Disconnect(); _v4mpFontConn = nil end
    for obj, origFont in pairs(_v4mpFontOrig) do
        pcall(function() if obj and obj.Parent then obj.FontFace = origFont end end)
    end
    _v4mpFontOrig = {}
end
function enablePotatoGraphics()
    V.potatoGraphicsEnabled = true
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 0.5
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ExposureCompensation = 0
        for _,e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect")
                or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
                e.Enabled = false
            end
        end
        for _,o in ipairs(Lighting:GetChildren()) do
            if o:IsA("Sky") then o:Destroy() end
        end
        local sky = Instance.new("Sky"); sky.Name = "_AceDuelsPotato"
        sky.CelestialBodiesShown = false
        sky.Parent = Lighting
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.Decoration = false
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
        end
    end)
    local function isCharPart(obj)
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
        end
        return false
    end
    local function potato(obj)
        if isCharPart(obj) then return end
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
                or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj.Enabled = false
            elseif obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
                obj.CastShadow = false
                obj.MaterialVariant = ""
            end
        end)
    end
    for _,obj in ipairs(workspace:GetDescendants()) do potato(obj) end
    if V.potatoConn then V.potatoConn:Disconnect() end
    V.potatoConn = workspace.DescendantAdded:Connect(function(obj)
        if V.potatoGraphicsEnabled then potato(obj) end
    end)
end
function disablePotatoGraphics()
    V.potatoGraphicsEnabled = false
    if V.potatoConn then V.potatoConn:Disconnect(); V.potatoConn = nil end
    pcall(function()
        local s = Lighting:FindFirstChild("_AceDuelsPotato")
        if s then s:Destroy() end
    end)
end
guiSizeValue = 1
mainGuiScale = nil
setGuiSizeVisual = nil
function applyGuiSize()
	guiSizeValue = math.clamp(tonumber(guiSizeValue) or 1, 0.75, 1.35)
	if mainGuiScale then mainGuiScale.Scale = guiSizeValue end
end

function saveConfig()
	local function ks(e) return {kb=e.kb and e.kb.Name or nil,gp=e.gp and e.gp.Name or nil} end
	local cfg={
		normalSpeed=NS,carrySpeed=CS,
		dropBrainrotKey=ks(KB.DropBrainrot),autoLeftKey=ks(KB.AutoLeft),autoRightKey=ks(KB.AutoRight),
		autoBatKey=ks(KB.AutoBat),antiDesyncAutoBatKey=ks(KB.AntiDesyncAutoBat),laggerToggleKey=ks(KB.LaggerToggle),tpFloorKey=ks(KB.TPFloor),instaResetKey=ks(KB.InstaReset),guiHideKey=ks(KB.GuiHide),
		speedToggleKey=ks(KB.SpeedToggle),
		grabRadius=Steal.NormalRadius or 60,stealDuration=1.3,
		stealMode=Steal.StealMode,normalAutoStealRadius=Steal.NormalRadius or 60,
		semiInstantStealRadius=Steal.SemiRadius or 9,
		antiRagdoll=antiRagdollEnabled,ragdollCountdown=ragdollCountdownEnabled,autoStealEnabled=Steal.AutoStealEnabled,
		infiniteJump=infJumpEnabled,medusaCounter=medusaCounterEnabled,autoReset=autoResetEnabled,
		batCounter=batCounterEnabled,
		carryMode=speedMode,laggerMode=laggerToggled,laggerCarryMode=laggerPhase==2,laggerSpeed=LAGGER_SPEED,laggerCarrySpeed=LAGGER_CARRY_SPEED,
		autoBat=false,autoLeft=false,autoRight=false,autoSwing=autoSwingEnabled,antiDesyncAutoBat=false,
		aimbotSpeed=aimbotSpeed,aimbotLaggerSpeed=aimbotLaggerSpeed,safeMode=antiKickEnabled,
		unwalkEnabled=unwalkEnabled,hitHarderAnim=hitHarderAnimEnabled,
		antiLag=antiLagEnabled,noCamCollision=noCamCollisionEnabled,stretchRez=stretchRezEnabled,
		customFov=V.customFovEnabled, customFovValue=V.customFovValue,
		skyTheme=V.skyTheme, ultraMode=V.ultraModeEnabled, removeAccessories=V.removeAccessoriesEnabledSep,
		customFontEnabled=V.customFontEnabled, potatoGraphics=V.potatoGraphicsEnabled, autoSave=V.autoSaveEnabled,
		autoTPEnabled=autoTPEnabled,autoTPHeight=autoTPHeight,
		lockGui=_guiLocked, introEnabled=_introEnabled, selectedIntroMusic=selectedIntroMusic, guiSize=guiSizeValue,
		themeAccent=V.themeAccent, sidebarArt=V.sidebarArt,
		playerESP=PlayerESP and PlayerESP.enabled or false,
	}
	if writefile then pcall(function() writefile("AceDuels.json",HS:JSONEncode(cfg)) end) end
end
task.spawn(function() while task.wait(5) do saveConfig() end end)
setInstaGrab,setInfJumpVisual,setAntiRagVisual,setMedusaVisual = nil, nil, nil, nil
setUnwalkVisual,setAntiLagVisual,setAutoSwingVisual,setSafeModeVisual = nil, nil, nil, nil
setRagdollCountdownVisual = nil
normalBox,carryBox,laggerBox,laggerCarryBox,radInput,durInput,autoTPHeightBox = nil, nil, nil, nil, nil, nil, nil
function refreshSpeedModeLabel()
	if modeValLbl then modeValLbl.Text=laggerToggled and (laggerPhase==2 and "Lagger Carry" or "Lagger Normal") or (speedMode and "Carry" or "Normal") end
end
function toggleCarryMode()
	if laggerToggled then
		laggerToggled=false
		laggerPhase=0
		speedMode=true
	else
		speedMode=not speedMode
	end
	refreshSpeedModeLabel()
end
function toggleLaggerMode()
	if not laggerToggled then
		speedMode=false
		laggerToggled=true
		laggerPhase=2
	elseif laggerPhase==2 then
		laggerPhase=1
	else
		laggerPhase=2
	end
	refreshSpeedModeLabel()
end
function buildGui()
	local BG    = Color3.fromRGB(8, 8, 8)
	local BG2   = Color3.fromRGB(14, 14, 14)
	local CARD  = Color3.fromRGB(20, 20, 20)
	local HOV   = Color3.fromRGB(50, 50, 50)
	-- THEME_ACCENT / trackTheme / setAccent are now defined at module scope (see top of file)
	-- Keep legacy refs working — RED/REDDIM now read current THEME at access via metatables not needed,
	-- but the old code paths use these locals. We'll update them at theme change too.
	local RED   = THEME_ACCENT
	local REDDIM= THEME_ACCENT_DIM
	local STROKE= Color3.fromRGB(80, 80, 80)
	local W     = Color3.fromRGB(250, 250, 250)
	local DIM   = Color3.fromRGB(160, 160, 160)
	local ACTIVE_TAB = Color3.fromRGB(185, 185, 185)
	local INP   = Color3.fromRGB(12, 12, 12)
	local OFF   = Color3.fromRGB(34, 34, 34)
	local coreGui=game:GetService("CoreGui")
	for _,oldName in ipairs({"AceDuels","Tooze"}) do
		local old=coreGui:FindFirstChild(oldName);if old then old:Destroy() end
	end
	local pg=LP:FindFirstChild("PlayerGui")
	if pg then
		for _,oldName in ipairs({"AceDuels","Tooze"}) do
			local o=pg:FindFirstChild(oldName);if o then o:Destroy() end
		end
	end
	local gui=Instance.new("ScreenGui")
	gui.Name="AceDuels";gui.ResetOnSpawn=false;gui.DisplayOrder=10;gui.IgnoreGuiInset=true
	gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling  -- Tooze FIX: per-parent stacking so nested rows/labels aren't hidden by ancestors
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	if not pcall(function() gui.Parent=game:GetService("CoreGui") end) then gui.Parent=LP:WaitForChild("PlayerGui") end
	local main=Instance.new("Frame",gui)
	main.AnchorPoint=Vector2.new(0.5, 0.5)  -- Tooze: centered like Green Duels
	main.Size=UDim2.new(0, 480, 0, 540)     -- Ace Duels: 1:1 Vampire-style frame size
	main.Position=UDim2.new(0.5, 0, 0.5, 0)
	main.BackgroundTransparency=1;main.BorderSizePixel=0;main.ClipsDescendants=true
	mainGuiScale = Instance.new("UIScale", main)
	applyGuiSize()
	-- Ace Duels: keep the very left top/bottom photo corners square (90 degrees).
	-- Right/content cards still keep their own rounded Vampire-style corners below.
	Instance.new("UICorner",main).CornerRadius=UDim.new(0,0)
	local panelScrim = Instance.new("Frame", main)
	panelScrim.Name = "PanelScrim";panelScrim.Size=UDim2.new(1,0,1,0);panelScrim.BackgroundTransparency=1;panelScrim.ZIndex=2
	local mainStroke=Instance.new("UIStroke",main)
	mainStroke.Color=THEME_ACCENT;mainStroke.Thickness=1.45;mainStroke.Transparency=1
	mainStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	trackTheme(function(c) mainStroke.Color = c end)
	local function drag(f)
		local dn,ds,sp,di=false
		f.InputBegan:Connect(function(i)
			if _guiLocked then return end
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				dn=true;ds=i.Position;sp=f.Position
				i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dn=false end end)
			end
		end)
		f.InputChanged:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end
		end)
		UIS.InputChanged:Connect(function(i)
			if i==di and dn then
				local nX=sp.X.Offset+(i.Position.X-ds.X)
				local nY=sp.Y.Offset+(i.Position.Y-ds.Y)
				f.Position=UDim2.new(sp.X.Scale,nX,sp.Y.Scale,nY)
			end
		end)
	end
	drag(main)
	-- =========================================================
	-- SIDEBAR area (LEFT side of unified panel) — transparent, holds image+tabs+brand
	-- =========================================================
	local SIDEBAR_W = 205
	local MENU_GAP = 0 -- clean split like Vampire Hub; no dark filtered gap between image and content
	local CONTENT_OVERLAP = 0
	local SIDEBAR_BG_OVERHANG = 0 -- no photo panel overhang; right side starts clean like Vampire
	local sidebar = Instance.new("Frame", main)
	sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
	sidebar.Position = UDim2.new(0, 0, 0, 0)  -- LEFT-aligned like Vampire Hub
	sidebar.BackgroundTransparency = 1
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 3
	sidebar.ClipsDescendants = true
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 0)
	-- Dark left panel background. Keep it behind everything and extend it slightly under the right menu
	-- so the menu is fully sitting on top of the dark section with no exposed seam.
	local sidebarArtClip = Instance.new("Frame", main)
	sidebarArtClip.Name = "SidebarArtClip"
	sidebarArtClip.Size = UDim2.new(0, SIDEBAR_W + SIDEBAR_BG_OVERHANG, 1, 0)
	sidebarArtClip.Position = UDim2.new(0, 0, 0, 0)
	sidebarArtClip.BackgroundTransparency = 1
	sidebarArtClip.BorderSizePixel = 0
	sidebarArtClip.ClipsDescendants = true
	sidebarArtClip.ZIndex = 1
	Instance.new("UICorner", sidebarArtClip).CornerRadius = UDim.new(0, 0)

	-- Sidebar photo background + clipped image so the rounded sidebar corners also clip the photo.
	sidebarArtClip.BackgroundColor3 = Color3.fromRGB(9, 9, 10)
	sidebarArtClip.BackgroundTransparency = 0
	local sidebarCanvas = Instance.new("CanvasGroup", sidebar)
	sidebarCanvas.Name = "SidebarCanvas"
	sidebarCanvas.Size = UDim2.new(1, 0, 1, 0)
	sidebarCanvas.Position = UDim2.new(0, 0, 0, 0)
	sidebarCanvas.BackgroundColor3 = Color3.fromRGB(8, 8, 9)
	sidebarCanvas.BackgroundTransparency = 0
	sidebarCanvas.BorderSizePixel = 0
	sidebarCanvas.ZIndex = 1
	Instance.new("UICorner", sidebarCanvas).CornerRadius = UDim.new(0, 0)
	local sidebarImage = Instance.new("ImageLabel", sidebarCanvas)
	sidebarImage.Name = "SidebarImage"
	sidebarImage.Size = UDim2.new(1.35, 0, 1, 0)
	sidebarImage.Position = UDim2.new(-0.35, 0, 0, 0) -- pushed photo as far right as possible while still fully covering the sidebar
	sidebarImage.BackgroundTransparency = 1
	sidebarImage.BorderSizePixel = 0
	sidebarImage.ScaleType = Enum.ScaleType.Crop
	sidebarImage.ImageTransparency = 0.08 -- show the user's sidebar photo
	sidebarImage.ZIndex = 2
	local function setSidebarArt(id)
		local finalId = tostring(id or "")
		if finalId == "" then finalId = DEFAULT_SIDEBAR_ART_ID end
		CURRENT_ART_ID = finalId
		V.sidebarArt = finalId
		sidebarImage.Image = "rbxassetid://" .. finalId
		sidebarImage.ImageTransparency = 0.08
	end
	setSidebarArt_global = setSidebarArt
	setSidebarArt(CURRENT_ART_ID ~= "" and CURRENT_ART_ID or DEFAULT_SIDEBAR_ART_ID)
	-- Dark scrim on top of image (muffles brightness, makes text/tabs readable)
	local sidebarScrim = Instance.new("Frame", sidebarArtClip)
	sidebarScrim.Name = "SidebarScrim"
	sidebarScrim.Size = UDim2.new(1, 0, 1, 0)
	sidebarScrim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	sidebarScrim.BackgroundTransparency = 0.10
	sidebarScrim.BorderSizePixel = 0
	sidebarScrim.ZIndex = 1  -- keep the dark backing behind the menu and sidebar content
	Instance.new("UICorner", sidebarScrim).CornerRadius = UDim.new(0, 0)

	-- Ace Duels sidebar card theme + sidebar photo.
	-- (no divider line — the content panel's own rounded border + lighter bg creates the visual separation)
	local sidebarDiv = Instance.new("Frame", main); sidebarDiv.Size=UDim2.new(0,0,0,0); sidebarDiv.Visible=false; sidebarDiv.ZIndex=0
	-- FPS/Ping at top-left of sidebar
	local statsBg = Instance.new("Frame", sidebar)
	statsBg.Size = UDim2.new(0, 118, 0, 24)
	statsBg.Position = UDim2.new(0, 8, 0, 7)
	statsBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	statsBg.BackgroundTransparency = 0.38
	statsBg.BorderSizePixel = 0
	statsBg.ZIndex = 4
	Instance.new("UICorner", statsBg).CornerRadius = UDim.new(0, 8)
	local statsBgStroke = Instance.new("UIStroke", statsBg)
	statsBgStroke.Color = Color3.fromRGB(58, 58, 62)
	statsBgStroke.Thickness = 1
	statsBgStroke.Transparency = 0.28
	local statsLbl = Instance.new("TextLabel", sidebar)
	statsLbl.Size = UDim2.new(1, -20, 0, 16)
	statsLbl.Position = UDim2.new(0, 14, 0, 11)
	statsLbl.BackgroundTransparency = 1
	statsLbl.Text = "FPS: -- | PING: --"
	statsLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
	statsLbl.Font = Enum.Font.GothamBold
	statsLbl.TextSize = 10
	statsLbl.TextXAlignment = Enum.TextXAlignment.Left
	statsLbl.ZIndex = 5
	statsLbl.BackgroundTransparency = 1
	trackTheme(function(c)
		statsLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
		if statsBgStroke then statsBgStroke.Color = Color3.fromRGB(70, 70, 74) end
	end)
	-- Tab buttons container — slightly above center, moderate gap
	local tabContainer = Instance.new("Frame", sidebar)
	tabContainer.Size = UDim2.new(0, 116, 0, 224)  -- centered tab stack like the reference
	tabContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	tabContainer.Position = UDim2.new(0.60, 0, 0.54, 0) -- shifted more to the right to match the reference
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 4
	local tabLayout = Instance.new("UIListLayout", tabContainer)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 38)
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	-- Brand area at bottom of sidebar
	-- Bottom-left Ace Duels / by Eugene branding removed by request
		-- =========================================================
	-- Right CONTENT AREA
	-- =========================================================
	local closeBtn = Instance.new("TextButton", main)
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -34, 0, 16)  -- top-right minimize box
	closeBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	closeBtn.BackgroundTransparency = 0.15
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "-";closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	closeBtn.Font = Enum.Font.GothamBold;closeBtn.TextSize = 18
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 10
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)
	local closeStroke = Instance.new("UIStroke", closeBtn)
	closeStroke.Color = THEME_ACCENT; closeStroke.Thickness = 1; closeStroke.Transparency = 0.45
	trackTheme(function(c) closeStroke.Color = c end)
	closeBtn.MouseEnter:Connect(function()
		TS:Create(closeBtn,TweenInfo.new(0.1),{TextColor3=Color3.fromRGB(0,0,0),BackgroundColor3=THEME_ACCENT_BRIGHT,BackgroundTransparency=0}):Play()
		TS:Create(closeStroke,TweenInfo.new(0.1),{Transparency=0.15}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TS:Create(closeBtn,TweenInfo.new(0.1),{TextColor3=Color3.fromRGB(200,200,200),BackgroundColor3=Color3.fromRGB(14,14,14),BackgroundTransparency=0.15}):Play()
		TS:Create(closeStroke,TweenInfo.new(0.1),{Transparency=0.45}):Play()
	end)
	-- FPS/Ping live update
	task.spawn(function()
		local lastFrame = tick()
		local fpsSamples = {}; local fpsAvg = 60
		RunService.RenderStepped:Connect(function()
			local now = tick(); local dt = now - lastFrame; lastFrame = now
			if dt > 0 then
				table.insert(fpsSamples, 1/dt)
				if #fpsSamples > 30 then table.remove(fpsSamples, 1) end
				local sum = 0; for _,v in ipairs(fpsSamples) do sum = sum + v end
				fpsAvg = sum / #fpsSamples
			end
		end)
		while statsLbl.Parent do
			local ping = 0
			pcall(function()
				local stat = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
				if stat then ping = math.floor(stat:GetValue() or 0) end
			end)
			statsLbl.Text = string.format("FPS: %d | PING: %dms", math.floor(fpsAvg+0.5), ping)
			task.wait(0.5)
		end
	end)
	-- mini button (when GUI hidden)
	local miniBtn=Instance.new("TextButton",gui)
	miniBtn.Size=UDim2.new(0,118,0,30);miniBtn.Position=UDim2.new(1,-144,0,26)
	miniBtn.BackgroundColor3=Color3.fromRGB(14, 14, 14);miniBtn.BorderSizePixel=0
	miniBtn.Text="Ace Duels";miniBtn.TextColor3=THEME_ACCENT;miniBtn.Font=Enum.Font.GothamBold;miniBtn.TextSize=12
	miniBtn.ZIndex=20;miniBtn.Visible=false
	Instance.new("UICorner",miniBtn).CornerRadius=UDim.new(0,8)
	local miniStroke=Instance.new("UIStroke",miniBtn);miniStroke.Color=THEME_ACCENT;miniStroke.Thickness=1.2;miniStroke.Transparency=0.4
	trackTheme(function(c) miniBtn.TextColor3 = c; miniStroke.Color = c end)
	drag(miniBtn)
	miniBtn.MouseEnter:Connect(function() TS:Create(miniBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(24, 24, 24)}):Play() end)
	miniBtn.MouseLeave:Connect(function() TS:Create(miniBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(14, 14, 14)}):Play() end)
	local function showGui() main.Visible=true;miniBtn.Visible=false end
	local function hideGui() main.Visible=false;miniBtn.Visible=true end
	closeBtn.MouseButton1Click:Connect(hideGui)
	miniBtn.MouseButton1Click:Connect(showGui)
	-- Cover left-side inner corners: behind contentArea (ZIndex=2) so content isn't hidden, fills gap against sidebar
	local innerCornerStrip = Instance.new("Frame", main)
	innerCornerStrip.Size = UDim2.new(0, 28, 1, 0)
	innerCornerStrip.Position = UDim2.new(0, (SIDEBAR_W - CONTENT_OVERLAP) + MENU_GAP, 0, 0)
	innerCornerStrip.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	innerCornerStrip.BorderSizePixel = 0
	innerCornerStrip.ZIndex = 2

	local contentArea = Instance.new("Frame", main)
	contentArea.Size = UDim2.new(1, -((SIDEBAR_W - CONTENT_OVERLAP) + MENU_GAP), 1, 0)
	contentArea.Position = UDim2.new(0, (SIDEBAR_W - CONTENT_OVERLAP) + MENU_GAP, 0, 0)  -- right panel sits over the sidebar edge like the reference
	contentArea.BackgroundColor3 = Color3.fromRGB(18, 18, 18) -- darker right-side background
	contentArea.BorderSizePixel = 0
	contentArea.ClipsDescendants = true
	contentArea.ZIndex = 3
	Instance.new("UICorner", contentArea).CornerRadius = UDim.new(0, 28)
	local contentSt = Instance.new("UIStroke", contentArea)
	contentSt.Color = Color3.fromRGB(70,70,70); contentSt.Thickness = 1; contentSt.Transparency = 1
	contentSt.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackTheme(function(c) contentSt.Color = c; contentSt.Transparency = 1 end)
	local splitCover = Instance.new("Frame", main)
	splitCover.Name = "SplitCover"
	splitCover.Size = UDim2.new(0, 0, 0, 0)
	splitCover.Visible = false
	splitCover.BorderSizePixel = 0
	splitCover.ZIndex = 0
	local topTabs = tabContainer  -- alias for backwards compatibility with makeTopTab
	-- legacy table refs kept for any old callers
	local tabBar = Instance.new("Frame", main)
	tabBar.Visible = false; tabBar.Size = UDim2.new(0, 0, 0, 0); tabBar.BorderSizePixel = 0; tabBar.ZIndex = 1
	local sf = contentArea
	local tabButtons = {}
	local tabPages = {}
	local currentTab = nil
	local function switchTab(name)
		currentTab = name
		for tn, pg in pairs(tabPages) do pg.Visible = (tn == name) end
	end
	-- pageHolder fills the contentArea (no top tab bar — tabs are in the sidebar)
	local pageHolder = Instance.new("Frame", contentArea)
	-- Inset the scrolling pages so the scrollbar stays inside the rounded content corners.
	pageHolder.Size = UDim2.new(1, -12, 1, -20)
	pageHolder.Position = UDim2.new(0, 6, 0, 10)
	pageHolder.BackgroundTransparency = 1
	pageHolder.BorderSizePixel = 0
	pageHolder.ZIndex = 3
	local topTabsLine = Instance.new("Frame", contentArea)  -- unused but kept for legacy refs
	topTabsLine.Visible = false; topTabsLine.Size = UDim2.new(0, 0, 0, 0); topTabsLine.ZIndex = 1
	-- Three pages with their own ScrollingFrames
	local function buildPage()
		local p = Instance.new("ScrollingFrame", pageHolder)
		p.Size = UDim2.new(1, -2, 1, 0)
		p.Position = UDim2.new(0, 0, 0, 0)
		p.BackgroundTransparency = 1
		p.BorderSizePixel = 0
		p.ClipsDescendants = true
		p.ScrollBarThickness = 0
		p.ScrollBarImageColor3 = THEME_ACCENT
		p.ScrollBarImageTransparency = 0.5
		p.CanvasSize = UDim2.new(0, 0, 0, 0)
		p.AutomaticCanvasSize = Enum.AutomaticSize.Y
		p.ZIndex = 4
		trackTheme(function(c) p.ScrollBarImageColor3 = c end)
		local ll = Instance.new("UIListLayout", p); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0, 7)
		local pd = Instance.new("UIPadding", p)
		pd.PaddingLeft = UDim.new(0, 8); pd.PaddingRight = UDim.new(0, 8)
		pd.PaddingTop = UDim.new(0, 8); pd.PaddingBottom = UDim.new(0, 18)
		return p
	end
	local mainPage = buildPage()
	local otherPage = buildPage(); otherPage.Visible = false
	local configPage = buildPage(); configPage.Visible = false
	sf = mainPage  -- default; mkSect/mkSectMerge can override
	-- Tab buttons
	local activePage = mainPage
	local function makeTopTab(label, idx, page)
		local b = Instance.new("TextButton", tabContainer)
		b.Size = UDim2.new(1, 0, 0, 42)
		b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		b.BackgroundTransparency = 0.34  -- transparent dark buttons over the sidebar art
		b.BorderSizePixel = 0
		b.Text = label:sub(1,1) .. label:sub(2):lower()
		b.TextColor3 = Color3.fromRGB(245, 245, 245)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
		b.AutoButtonColor = false
		b.LayoutOrder = idx
		b.ZIndex = 5
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
		local s = Instance.new("UIStroke", b)
		s.Color = Color3.fromRGB(88,88,88); s.Thickness = 1; s.Transparency = 0.55
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		b.MouseEnter:Connect(function()
			if activePage ~= page then
				TS:Create(b, TweenInfo.new(0.12), {
					BackgroundTransparency = 0.12,
					BackgroundColor3 = Color3.fromRGB(225, 225, 225),
					TextColor3 = Color3.fromRGB(0, 0, 0),
				}):Play()
			end
		end)
		b.MouseLeave:Connect(function()
			if activePage ~= page then
				TS:Create(b, TweenInfo.new(0.12), {
					BackgroundTransparency = 0.34,
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					TextColor3 = Color3.fromRGB(245, 245, 245),
				}):Play()
			end
		end)
		local underline = Instance.new("Frame", b)
		underline.Size = UDim2.new(0, 0, 0, 0); underline.BackgroundTransparency = 1
		return b, underline
	end
	local btnMain,   ulMain   = makeTopTab("MAIN",   1, mainPage)
	local btnOther,  ulOther  = makeTopTab("OTHER",  2, otherPage)
	local btnConfig, ulConfig = makeTopTab("CONFIG", 3, configPage)
	local allTabs = {
		{btn=btnMain,   ul=ulMain,   page=mainPage},
		{btn=btnOther,  ul=ulOther,  page=otherPage},
		{btn=btnConfig, ul=ulConfig, page=configPage},
	}
	local function setActivePage(p)
		activePage = p
		for _, t in ipairs(allTabs) do
			t.page.Visible = (t.page == p)
			local isActive = (t.page == p)
			TS:Create(t.btn, TweenInfo.new(0.22), {
				BackgroundColor3 = isActive and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(20, 20, 20),
				BackgroundTransparency = isActive and 0 or 0.34,  -- keep selected tab grey until another tab is clicked
				TextColor3 = isActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(245, 245, 245),
			}):Play()
			local st = t.btn:FindFirstChildWhichIsA("UIStroke")
			if st then
				TS:Create(st, TweenInfo.new(0.22), {
					Color = isActive and Color3.fromRGB(225, 225, 225) or Color3.fromRGB(120, 120, 120),
					Transparency = isActive and 0.2 or 0.5,
				}):Play()
			end
		end
	end
	-- default active: Main
	btnMain.BackgroundColor3 = ACTIVE_TAB; btnMain.BackgroundTransparency = 0; btnMain.TextColor3 = Color3.fromRGB(0, 0, 0)
	do
		local st = btnMain:FindFirstChildWhichIsA("UIStroke")
		if st then st.Color = Color3.fromRGB(225, 225, 225); st.Transparency = 0.2 end
	end
	-- When theme changes, re-run setActivePage to refresh active tab color + strokes for all tabs
	trackTheme(function(_) setActivePage(activePage) end)
	btnMain.MouseButton1Click:Connect(function()   setActivePage(mainPage)   end)
	btnOther.MouseButton1Click:Connect(function()  setActivePage(otherPage)  end)
	btnConfig.MouseButton1Click:Connect(function() setActivePage(configPage) end)
	-- Map sections to pages: Speed/Combat/Steal → Main; Visual → Other; Interface → Config
	-- Vampire Hub-style sorting: MAIN = Speed/Combat/Mechanics, OTHER = Movement/TP, CONFIG = Steal/Display/Interface
	local SECTION_TO_PAGE = {
		Speed = mainPage, ["Lagger Speed"] = mainPage, Steal = mainPage, ["Grab Radius"] = mainPage, AIMBOT = mainPage, Combat = mainPage, Mechanics = mainPage, Teleport = mainPage, Keybinds = mainPage, Misc = mainPage,
		Auto = otherPage, Movement = otherPage, Visuals = otherPage, Visual = otherPage, FOV = otherPage,
		Display = configPage, Interface = configPage, ["GUI Settings"] = configPage, Config = configPage,
	}
	local tabOrder = 0
	local lo = 0
	local function LO() lo = lo + 1; return lo end
	local function mkSect(txt)
		tabOrder = tabOrder + 1
		local targetPage = SECTION_TO_PAGE[txt] or mainPage
		sf = targetPage
		tabPages[txt] = targetPage
		local f = Instance.new("Frame", targetPage)
		f.Size = UDim2.new(1, 0, 0, 38); f.BackgroundTransparency = 1
		f.BorderSizePixel = 0; f.LayoutOrder = LO(); f.ZIndex = 6
		local l = Instance.new("TextLabel", f)
		l.Size = UDim2.new(1, 0, 1, -10); l.Position = UDim2.new(0, 0, 0, 2)
		l.BackgroundTransparency = 1; l.Text = txt:upper(); l.TextColor3 = THEME_ACCENT
		l.Font = Enum.Font.GothamBlack; l.TextSize = 12
		l.TextXAlignment = Enum.TextXAlignment.Center
		l.ZIndex = 9
		local line = Instance.new("Frame", f)
		line.Size = UDim2.new(1, -24, 0, 1)
		line.Position = UDim2.new(0, 12, 1, -4)
		line.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		line.BorderSizePixel = 0
		line.ZIndex = 8
		trackTheme(function(c) l.TextColor3 = c end)
	end
	local function mkSectMerge(txt)
		local sp=Instance.new("Frame",sf);sp.Size=UDim2.new(1,0,0,10);sp.BackgroundTransparency=1;sp.BorderSizePixel=0;sp.LayoutOrder=LO();sp.ZIndex=6
		local f=Instance.new("Frame",sf);f.Size=UDim2.new(1,0,0,28);f.BackgroundTransparency=1;f.BorderSizePixel=0;f.LayoutOrder=LO();f.ZIndex=6
		local l=Instance.new("TextLabel",f);l.Size=UDim2.new(1,0,1,-10);l.Position=UDim2.new(0,0,0,2)
		l.BackgroundTransparency=1;l.Text=txt:upper();l.TextColor3=THEME_ACCENT
		l.Font=Enum.Font.GothamBlack;l.TextSize=10;l.TextXAlignment=Enum.TextXAlignment.Center
		l.ZIndex=9
		local line=Instance.new("Frame",f);line.Size=UDim2.new(1,-24,0,1);line.Position=UDim2.new(0,12,1,-4)
		line.BackgroundColor3=Color3.fromRGB(70, 70, 70);line.BorderSizePixel=0;line.ZIndex=8
		trackTheme(function(c) if l and l.Parent then l.TextColor3 = c end end)
	end
	local function mkRow(h)
		local f=Instance.new("Frame",sf);f.Size=UDim2.new(1,-2,0,h or 40)  -- 1:1 Vampire Hub row size
		f.BackgroundColor3=Color3.fromRGB(0, 0, 0);f.BorderSizePixel=0;f.LayoutOrder=LO()  -- Vampire-style black cards
		f.ZIndex=6
		Instance.new("UICorner",f).CornerRadius=UDim.new(0,10)  -- Vampire Hub rounded card
		local rs=Instance.new("UIStroke",f); rs.Color=Color3.fromRGB(92, 92, 92); rs.Thickness=1; rs.Transparency=0.18  -- silver-grey stroke
		f.MouseEnter:Connect(function() TS:Create(f,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(10, 10, 10)}):Play() end)
		f.MouseLeave:Connect(function() TS:Create(f,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(0, 0, 0)}):Play() end)
		return f
	end
	local function mkLabel(row,txt)
		local l=Instance.new("TextLabel",row);l.Size=UDim2.new(0.58,0,1,0);l.Position=UDim2.new(0,11,0,0)
		l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=W
		l.Font=Enum.Font.GothamBold;l.TextSize=11;l.TextXAlignment=Enum.TextXAlignment.Left
		l.ZIndex=8
	end
	local function mkPill(row,offset)
		local pill=Instance.new("Frame",row);pill.Size=UDim2.new(0,46,0,24)
		pill.Position=UDim2.new(1,-(offset or 56),0.5,-12)
		pill.BackgroundColor3=Color3.fromRGB(42, 42, 42);pill.BorderSizePixel=0;pill.ZIndex=3
		Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
		local dot=Instance.new("Frame",pill);dot.Size=UDim2.new(0,18,0,18);dot.Position=UDim2.new(0,3,0.5,-9)
		dot.BackgroundColor3=Color3.fromRGB(130, 130, 130);dot.BorderSizePixel=0;dot.ZIndex=4
		Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
		return pill,dot
	end
	local function animPill(pill,dot,on)
		TS:Create(pill,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{BackgroundColor3=on and THEME_ACCENT or Color3.fromRGB(34, 34, 34)}):Play()
		TS:Create(dot,TweenInfo.new(0.18,Enum.EasingStyle.Back),{
			Position=on and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
			BackgroundColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(130, 130, 130)
		}):Play()
	end
	local _trackedPills = {}  -- {pill, dot, getState fn}
	trackTheme(function(_) for _,t in ipairs(_trackedPills) do if t.getState() then animPill(t.pill, t.dot, true) end end end)
	local function mkToggle(txt,cb)
		local row=mkRow(40);mkLabel(row,txt)
		local pill,dot=mkPill(row,56)
		local on=false
		local function sv(s) on=s;animPill(pill,dot,s) end
		table.insert(_trackedPills, {pill=pill, dot=dot, getState=function() return on end})
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=5
		clk.Activated:Connect(function()
			on=not on;sv(on)
			pcall(cb, on)
			pcall(saveConfig)  -- AUTO-SAVE every toggle change, regardless of cb
		end)
		pill.ZIndex=3;dot.ZIndex=4
		return sv
	end
	local function mkBox(parent,default,w,xOff,cb)
		local tb=Instance.new("TextBox",parent)
		local bw = w or 74
		local xo = math.max(xOff or 78, bw + 8)
		tb.Size=UDim2.new(0,bw,0,26);tb.Position=UDim2.new(1,-xo,0.5,-13)
		tb.BackgroundColor3=Color3.fromRGB(12, 12, 12);tb.BorderSizePixel=0;tb.Text=tostring(default);tb.TextColor3=THEME_ACCENT
		tb.Font=Enum.Font.GothamBold;tb.TextSize=11;tb.ClearTextOnFocus=false;tb.ZIndex=5
		Instance.new("UICorner",tb).CornerRadius=UDim.new(0,7)
		local bs=Instance.new("UIStroke",tb);bs.Color=Color3.fromRGB(80, 80, 80);bs.Thickness=1;bs.Transparency=0.28
		tb.Focused:Connect(function() TS:Create(bs,TweenInfo.new(0.12),{Color=THEME_ACCENT,Transparency=0}):Play() end)
		tb.FocusLost:Connect(function()
			TS:Create(bs,TweenInfo.new(0.12),{Color=Color3.fromRGB(80, 80, 80),Transparency=0.28}):Play()
			if cb then local n=tonumber(tb.Text);if n then cb(n) else tb.Text=tostring(default) end end
			pcall(saveConfig)  -- AUTO-SAVE on every value commit
		end)
		return tb
	end
	local function mkSlider(parent,default,minVal,maxVal,step,cb,suffix)
		local value=tonumber(default) or minVal
		local dragging=false
		local dragAbsX,dragAbsW=nil,nil
		local hitbox=Instance.new("TextButton",parent)
		hitbox.Size=UDim2.new(0,138,0,30);hitbox.Position=UDim2.new(1,-184,0.5,-15)
		hitbox.BackgroundTransparency=1;hitbox.Text="";hitbox.AutoButtonColor=false;hitbox.ZIndex=9
		local track=Instance.new("Frame",parent)
		track.Size=UDim2.new(0,112,0,8);track.Position=UDim2.new(1,-170,0.5,-4)
		track.BackgroundColor3=Color3.fromRGB(38,38,38);track.BorderSizePixel=0;track.ZIndex=6
		Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
		local fill=Instance.new("Frame",track)
		fill.Size=UDim2.new(0,0,1,0);fill.BackgroundColor3=THEME_ACCENT;fill.BorderSizePixel=0;fill.ZIndex=7
		Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
		local knob=Instance.new("Frame",track)
		knob.Size=UDim2.new(0,18,0,18);knob.Position=UDim2.new(0,-9,0.5,-9)
		knob.BackgroundColor3=Color3.fromRGB(245,245,245);knob.BorderSizePixel=0;knob.ZIndex=8
		Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
		local valLbl=Instance.new("TextLabel",parent)
		valLbl.Size=UDim2.new(0,42,1,0);valLbl.Position=UDim2.new(1,-46,0,0)
		valLbl.BackgroundTransparency=1;valLbl.TextColor3=THEME_ACCENT;valLbl.Font=Enum.Font.GothamBold;valLbl.TextSize=11;valLbl.TextXAlignment=Enum.TextXAlignment.Right;valLbl.ZIndex=8
		trackTheme(function(c) if fill and fill.Parent then fill.BackgroundColor3=c end;if valLbl and valLbl.Parent then valLbl.TextColor3=c end end)
		local function fmt(v) return string.format("%.2f",v)..(suffix or "") end
		local function setValue(v,runCb)
			v=math.clamp(tonumber(v) or minVal,minVal,maxVal)
			if step and step>0 then v=math.floor((v-minVal)/step+0.5)*step+minVal end
			v=math.clamp(v,minVal,maxVal)
			value=v
			local a=(value-minVal)/(maxVal-minVal)
			fill.Size=UDim2.new(a,0,1,0)
			knob.Position=UDim2.new(a,-9,0.5,-9)
			valLbl.Text=fmt(value)
			if runCb and cb then cb(value) end
		end
		local function setFromX(x,runCb)
			local absX=dragAbsX or track.AbsolutePosition.X
			local absW=dragAbsW or math.max(track.AbsoluteSize.X,1)
			local a=math.clamp((x-absX)/math.max(absW,1),0,1)
			setValue(minVal+(maxVal-minVal)*a,runCb)
		end
		local function finishDrag()
			if not dragging then return end
			dragging=false;dragAbsX=nil;dragAbsW=nil
			pcall(saveConfig)
		end
		local function begin(input)
			if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
				dragging=true
				dragAbsX=track.AbsolutePosition.X
				dragAbsW=math.max(track.AbsoluteSize.X,1)
				setFromX(input.Position.X,true)
			end
		end
		hitbox.InputBegan:Connect(begin);track.InputBegan:Connect(begin);knob.InputBegan:Connect(begin)
		UIS.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
				setFromX(input.Position.X,true)
			end
		end)
		UIS.InputEnded:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
				finishDrag()
			end
		end)
		setValue(value,false)
		return setValue
	end

	local GAMEPAD_KEYS={
		[Enum.KeyCode.ButtonA]=true,[Enum.KeyCode.ButtonB]=true,[Enum.KeyCode.ButtonX]=true,[Enum.KeyCode.ButtonY]=true,
		[Enum.KeyCode.ButtonL1]=true,[Enum.KeyCode.ButtonR1]=true,[Enum.KeyCode.ButtonL2]=true,[Enum.KeyCode.ButtonR2]=true,
		[Enum.KeyCode.ButtonL3]=true,[Enum.KeyCode.ButtonR3]=true,[Enum.KeyCode.ButtonStart]=true,[Enum.KeyCode.ButtonSelect]=true,
		[Enum.KeyCode.DPadUp]=true,[Enum.KeyCode.DPadDown]=true,[Enum.KeyCode.DPadLeft]=true,[Enum.KeyCode.DPadRight]=true
	}
	local function isGamepadInput(inp) return inp and inp.UserInputType and inp.UserInputType.Name:match("^Gamepad")~=nil end
	local function isBindableInput(inp)
		if not inp or inp.KeyCode==Enum.KeyCode.Unknown then return false end
		if inp.UserInputType==Enum.UserInputType.Keyboard then return true end
		return isGamepadInput(inp) and GAMEPAD_KEYS[inp.KeyCode]==true
	end
	local function kbMatch(entry,kc) return kc and (kc==entry.kb or (entry.gp and kc==entry.gp)) end
	local function mkKB(parent,kbEntry,cb)
		local btn=Instance.new("TextButton",parent)
		btn.Size=UDim2.new(0,70,0,26);btn.Position=UDim2.new(1,-78,0.5,-13)
		btn.BackgroundColor3=Color3.fromRGB(12, 12, 12);btn.BorderSizePixel=0
		local function getLabel() return (kbEntry.gp and kbEntry.gp.Name) or (kbEntry.kb and kbEntry.kb.Name) or "None" end
		btn.Text=getLabel();btn.TextColor3=THEME_ACCENT
		btn.Font=Enum.Font.GothamBold;btn.TextSize=11;btn.ZIndex=5
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
		local kbSt=Instance.new("UIStroke",btn);kbSt.Color=Color3.fromRGB(80, 80, 80);kbSt.Thickness=1;kbSt.Transparency=0.28  -- silver-grey stroke
		local li=false;local lc;local pv=btn.Text;local listenStart=0;local listenGeneration=0
		btn.Activated:Connect(function()
			if li then li=false;_anyKeyListening=false;if lc then lc:Disconnect();lc=nil end;btn.Text=pv;btn.TextColor3=W;return end
			_keyListenGeneration=_keyListenGeneration+1;listenGeneration=_keyListenGeneration
			pv=btn.Text;li=true;_anyKeyListening=true;listenStart=tick();btn.Text="...";btn.TextColor3=W
			lc=UIS.InputBegan:Connect(function(inp)
				if not li then return end
				if inp.KeyCode==Enum.KeyCode.Escape then li=false;_anyKeyListening=false;if lc then lc:Disconnect();lc=nil end;btn.Text=pv;btn.TextColor3=W;return end
				local isGp=isGamepadInput(inp)
				if isGp and tick()-listenStart<0.15 then return end
				if not isBindableInput(inp) then return end
				btn.Text=inp.KeyCode.Name;pv=inp.KeyCode.Name;btn.TextColor3=W
				li=false;if lc then lc:Disconnect();lc=nil end
				if cb then cb(inp.KeyCode,isGp) end
				local releaseGeneration=listenGeneration
				task.delay(0.2,function()
					if _keyListenGeneration==releaseGeneration then _anyKeyListening=false end
				end)
			end)
		end)
		return btn
	end
	local function mkToggleKB(txt,kbEntry,onToggle,onKB)
		local row=mkRow(40);mkLabel(row,txt)  -- Tooze: 40px row
		if kbEntry then mkKB(row,kbEntry,function(k,isGp)
			if isGp then kbEntry.gp=k;kbEntry.kb=nil else kbEntry.kb=k;kbEntry.gp=nil end
			if onKB then onKB(k,isGp) end
		end) end
		local pill,dot=mkPill(row,kbEntry and 134 or 56)  -- Tooze: pill at -134 from right when keybind (58 KB width + 12 gap + 56 = 126ish, give 134 for safety)
		local on=false
		local function sv(s) on=s;animPill(pill,dot,s) end
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=5
		clk.Activated:Connect(function() if _anyKeyListening then return end;on=not on;sv(on);if onToggle then onToggle(on) end end)
		pill.ZIndex=3;dot.ZIndex=4
		return sv
	end
	-- Tooze: unified progress bar — STEAL + fill + percentage live inside ONE pill (no separate chip)
	local pbFrame=Instance.new("Frame",gui)
	pbFrame.Size=UDim2.new(0,380,0,38);pbFrame.Position=UDim2.new(0.5,-190,1,-90)
	pbFrame.BackgroundColor3=Color3.fromRGB(0, 0, 0);pbFrame.BorderSizePixel=0;pbFrame.Active=true;pbFrame.ClipsDescendants=true
	Instance.new("UICorner",pbFrame).CornerRadius=UDim.new(1,0)
	local pbSt=Instance.new("UIStroke",pbFrame); pbSt.Color=THEME_ACCENT; pbSt.Thickness=1.2; pbSt.Transparency=0.2
	drag(pbFrame)

	-- Ragdoll/hit countdown is created above the overhead Discord text in setupSpeedIndicator().
	-- The unified left pill (STEAL + fill + percentage all in one element)
	local fillRegion = Instance.new("Frame", pbFrame)
	fillRegion.Size = UDim2.new(0, 220, 1, -8)
	fillRegion.Position = UDim2.new(0, 5, 0, 4)
	fillRegion.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	fillRegion.BorderSizePixel = 0
	fillRegion.ClipsDescendants = true
	fillRegion.ZIndex = 2
	Instance.new("UICorner", fillRegion).CornerRadius = UDim.new(1, 0)
	-- subtle vertical gradient on the dark track for depth
	local fillRegGradient = Instance.new("UIGradient", fillRegion)
	fillRegGradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(14, 14, 14))
	fillRegGradient.Rotation = 90
	local fillRegStroke = Instance.new("UIStroke", fillRegion)
	fillRegStroke.Color = THEME_ACCENT; fillRegStroke.Thickness = 1; fillRegStroke.Transparency = 0.6
	trackTheme(function(c) fillRegStroke.Color = c end)
	-- The fill: grows from left, colored with a vertical gradient for a premium look
	progressFill=Instance.new("Frame",fillRegion)
	progressFill.Size=UDim2.new(0,0,1,0);progressFill.Position=UDim2.new(0,0,0,0)
	progressFill.BackgroundColor3=THEME_ACCENT;progressFill.BorderSizePixel=0
	progressFill.ZIndex=3
	Instance.new("UICorner",progressFill).CornerRadius=UDim.new(1,0)
	local fillGradient = Instance.new("UIGradient", progressFill)
	fillGradient.Color = ColorSequence.new(THEME_ACCENT_BRIGHT, THEME_ACCENT_DIM)
	fillGradient.Rotation = 90
	trackTheme(function(c)
		progressFill.BackgroundColor3 = c
		fillGradient.Color = ColorSequence.new(THEME_ACCENT_BRIGHT, THEME_ACCENT_DIM)
	end)
	-- STEAL text overlaid on the LEFT of fillRegion (always visible)
	local stealLbl = Instance.new("TextLabel", fillRegion)
	stealLbl.Size = UDim2.new(0, 60, 1, 0)
	stealLbl.Position = UDim2.new(0, 12, 0, 0)
	stealLbl.BackgroundTransparency = 1
	stealLbl.Text = "STEAL"
	stealLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	stealLbl.Font = Enum.Font.GothamBlack
	stealLbl.TextSize = 11
	stealLbl.TextXAlignment = Enum.TextXAlignment.Left
	stealLbl.ZIndex = 5
	-- percentage/distance text on the RIGHT of fillRegion (always visible)
	progressPct=Instance.new("TextLabel",fillRegion)
	progressPct.Size=UDim2.new(0,60,1,0);progressPct.Position=UDim2.new(1,-68,0,0)
	progressPct.BackgroundTransparency=1;progressPct.Text="—";progressPct.TextColor3=Color3.fromRGB(230, 230, 230)
	progressPct.Font=Enum.Font.GothamBold;progressPct.TextSize=10
	progressPct.TextXAlignment=Enum.TextXAlignment.Right
	progressPct.ZIndex=5
	-- vertical divider
	local pbDiv = Instance.new("Frame", pbFrame)
	pbDiv.Size = UDim2.new(0, 1, 1, 0)
	pbDiv.Position = UDim2.new(0, 232, 0, 0)
	pbDiv.BackgroundColor3 = THEME_ACCENT
	pbDiv.BackgroundTransparency = 0.5
	pbDiv.BorderSizePixel = 0
	pbDiv.ZIndex = 3
	trackTheme(function(c) pbDiv.BackgroundColor3 = c end)
	-- FPS · PING info on the right (now occupies the full right area)
	progressRadLbl=Instance.new("TextLabel",pbFrame)
	progressRadLbl.Size=UDim2.new(0,140,1,0);progressRadLbl.Position=UDim2.new(0,236,0,0)
	progressRadLbl.BackgroundTransparency=1;progressRadLbl.Text="-- · --"
	progressRadLbl.TextColor3=Color3.fromRGB(190, 190, 190);progressRadLbl.Font=Enum.Font.GothamBold;progressRadLbl.TextSize=10
	progressRadLbl.TextXAlignment=Enum.TextXAlignment.Center
	progressRadLbl.ZIndex=4
	-- Tooze: status state machine — IDLE / READY (in steal range) / STEALING
	-- READY state pulses the right-side dot and shows distance to the nearest prompt
	local _pbState = "IDLE"
	local function setBarState(state, distance)
		_pbState = state
		if state == "STEALING" then
			TS:Create(stealLbl,   TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			TS:Create(fillRegion, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 26, 36)}):Play()
		elseif state == "READY" then
			TS:Create(stealLbl,   TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			TS:Create(fillRegion, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 50, 80)}):Play()
			if progressPct then
				progressPct.Text = distance and (math.floor(distance).."m") or "READY"
				progressPct.TextColor3 = Color3.fromRGB(235, 235, 235)
			end
		else  -- IDLE
			TS:Create(stealLbl,   TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
			TS:Create(fillRegion, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 26, 36)}):Play()
			if progressPct and not isStealing then
				progressPct.Text = distance and (math.floor(distance).."m") or "—"
				progressPct.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
		end
	end
	-- scan loop: detects nearby steal prompts and switches the bar between IDLE / READY (always running, independent of auto-steal toggle)
	task.spawn(function()
		while task.wait(0.25) do
			if Steal.StealMode=="Semi" then continue end
			local normalResultVisible=normalStealState.lastResultTime>0 and tick()-normalStealState.lastResultTime<1.4
			if isStealing then
				setBarState("STEALING")
			elseif normalResultVisible then
				-- The synchronized auto-steal renderer owns the completed-result bar.
			else
				local p, d = findNearestPrompt()
				nearestPromptCache, nearestPromptDist = p, d
				if p then
					setBarState("READY", d)
				else
					local nearDist = nil
					local rootPart = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
					if rootPart and Steal.cachedPrompts then
						local best = math.huge
						for _, data in ipairs(Steal.cachedPrompts) do
							if data.spawn and data.spawn.Parent then
								local dist = (data.spawn.Position - rootPart.Position).Magnitude
								if dist < best then best = dist end
							end
						end
						if best < math.huge then nearDist = best end
					end
					setBarState("IDLE", nearDist)
				end
			end
		end
	end)
	-- live FPS · PING update — reuses the stats loop pattern from the main header
	task.spawn(function()
		local lastFrame = tick()
		local fpsSamples = {}; local fpsAvg = 60
		RunService.RenderStepped:Connect(function()
			local now = tick(); local dt = now - lastFrame; lastFrame = now
			if dt > 0 then
				table.insert(fpsSamples, 1/dt)
				if #fpsSamples > 30 then table.remove(fpsSamples, 1) end
				local sum = 0; for _,v in ipairs(fpsSamples) do sum = sum + v end
				fpsAvg = sum / #fpsSamples
			end
		end)
		while mainGui and mainGui.Parent do
			local ping = 0
			pcall(function() ping = LP:GetNetworkPing() * 1000 end)
			if progressRadLbl then
				progressRadLbl.Text = string.format("%d FPS | %dms | R:%.2g", math.floor(fpsAvg+0.5), math.floor(ping+0.5), Steal.StealRadius)
				progressRadLbl.TextColor3=Color3.fromRGB(190,190,190)
			end
			task.wait(0.5)
		end
	end)
	mkSect("Speed")
	do local row=mkRow(40);mkLabel(row,"Normal Speed");normalBox=mkBox(row,NS,50,48,function(v) if v>0 and v<=500 then NS=v end;saveConfig() end) end
	do local row=mkRow(40);mkLabel(row,"Carry Speed");carryBox=mkBox(row,CS,50,48,function(v) if v>0 and v<=500 then CS=v end;saveConfig() end) end
	do local row=mkRow(40);mkLabel(row,"Speed Key");mkKB(row,KB.SpeedToggle,function(k,isGp) if isGp then KB.SpeedToggle.gp=k;KB.SpeedToggle.kb=nil else KB.SpeedToggle.kb=k;KB.SpeedToggle.gp=nil end;saveConfig() end) end
	do
		local row=mkRow(40);mkLabel(row,"Mode")
		modeValLbl=Instance.new("TextLabel",row)
		modeValLbl.Size=UDim2.new(0,100,1,0);modeValLbl.Position=UDim2.new(1,-104,0,0)
		modeValLbl.BackgroundTransparency=1;modeValLbl.Text="Normal";modeValLbl.TextColor3=THEME_ACCENT
		modeValLbl.Font=Enum.Font.GothamBlack;modeValLbl.TextSize=12;modeValLbl.TextXAlignment=Enum.TextXAlignment.Right;modeValLbl.ZIndex=8
		do local _modeLbl=modeValLbl; trackTheme(function(c) if _modeLbl and _modeLbl.Parent then _modeLbl.TextColor3 = c end end) end
		local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(function() if _anyKeyListening then return end; toggleCarryMode(); saveConfig() end)
	end

	mkSect("Lagger Speed")
	do local row=mkRow(40);mkLabel(row,"Lagger Normal");laggerBox=mkBox(row,LAGGER_SPEED,50,48,function(v) if v>0 and v<=500 then LAGGER_SPEED=v end;saveConfig() end) end
	do local row=mkRow(40);mkLabel(row,"Lagger Carry");laggerCarryBox=mkBox(row,LAGGER_CARRY_SPEED,50,48,function(v) if v>0 and v<=500 then LAGGER_CARRY_SPEED=v end;saveConfig() end) end
	do local row=mkRow(40);mkLabel(row,"Lagger Key");mkKB(row,KB.LaggerToggle,function(k,isGp) if isGp then KB.LaggerToggle.gp=k;KB.LaggerToggle.kb=nil else KB.LaggerToggle.kb=k;KB.LaggerToggle.gp=nil end;saveConfig() end) end
	do
		local row=mkRow(40);mkLabel(row,"Mode")
		local laggerModeLbl=Instance.new("TextLabel",row)
		laggerModeLbl.Size=UDim2.new(0,100,1,0);laggerModeLbl.Position=UDim2.new(1,-104,0,0)
		laggerModeLbl.BackgroundTransparency=1;laggerModeLbl.Text="Normal";laggerModeLbl.TextColor3=THEME_ACCENT
		laggerModeLbl.Font=Enum.Font.GothamBlack;laggerModeLbl.TextSize=12;laggerModeLbl.TextXAlignment=Enum.TextXAlignment.Right;laggerModeLbl.ZIndex=8
		trackTheme(function(c) if laggerModeLbl and laggerModeLbl.Parent then laggerModeLbl.TextColor3 = c end end)
		local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(function() if _anyKeyListening then return end; toggleLaggerMode(); laggerModeLbl.Text=laggerToggled and "Lagger" or "Normal"; saveConfig() end)
	end

	mkSect("Steal")
	local stealTypeValue,stealRecommendation
	local function refreshStealTypeUi()
		if stealTypeValue then stealTypeValue.Text=(Steal.StealMode=="Semi") and "Semi Instant Steal  v" or "Normal Auto Steal  v" end
		if radInput then radInput.Text=tostring(Steal.StealRadius) end
		if stealRecommendation then stealRecommendation.Text="Recommended Radius: "..((Steal.StealMode=="Semi") and "9" or "60") end
	end
	do
		local row=mkRow(40);mkLabel(row,"Steal Type")
		stealTypeValue=Instance.new("TextButton",row)
		stealTypeValue.Size=UDim2.new(0,170,0,28);stealTypeValue.Position=UDim2.new(1,-178,0,6)
		stealTypeValue.BackgroundColor3=Color3.fromRGB(12,12,12);stealTypeValue.BorderSizePixel=0
		stealTypeValue.TextColor3=THEME_ACCENT;stealTypeValue.Font=Enum.Font.GothamBold;stealTypeValue.TextSize=10;stealTypeValue.ZIndex=10;stealTypeValue.AutoButtonColor=false
		Instance.new("UICorner",stealTypeValue).CornerRadius=UDim.new(0,7)
		local menu=Instance.new("Frame",row)
		menu.Size=UDim2.new(0,170,0,64);menu.Position=UDim2.new(1,-178,0,38);menu.BackgroundColor3=Color3.fromRGB(7,7,7);menu.BorderSizePixel=0;menu.Visible=false;menu.ZIndex=15
		Instance.new("UICorner",menu).CornerRadius=UDim.new(0,7)
		local menuStroke=Instance.new("UIStroke",menu);menuStroke.Color=THEME_ACCENT;menuStroke.Transparency=0.25
		local function option(text,y,mode)
			local b=Instance.new("TextButton",menu);b.Size=UDim2.new(1,-8,0,27);b.Position=UDim2.new(0,4,0,y)
			b.BackgroundColor3=Color3.fromRGB(15,15,15);b.BorderSizePixel=0;b.Text=text;b.TextColor3=Color3.fromRGB(225,225,225);b.Font=Enum.Font.GothamBold;b.TextSize=10;b.ZIndex=16
			Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
			b.Activated:Connect(function()
				local wasOn=Steal.AutoStealEnabled;if wasOn then stopAutoSteal() end
				setStealMode(mode);menu.Visible=false;row.Size=UDim2.new(1,-2,0,40)
				if wasOn then Steal.AutoStealEnabled=true;pcall(startAutoSteal) end
				refreshStealTypeUi();saveConfig()
			end)
		end
		option("Normal Auto Steal",4,"Normal");option("Semi Instant Steal",33,"Semi")
		stealTypeValue.Activated:Connect(function()
			menu.Visible=not menu.Visible;row.Size=UDim2.new(1,-2,0,menu.Visible and 106 or 40)
		end)
		trackTheme(function(c) if stealTypeValue and stealTypeValue.Parent then stealTypeValue.TextColor3=c;menuStroke.Color=c end end)
	end
	do
		local stealRow=mkRow(40);mkLabel(stealRow,"Auto Steal")
		local pill,dot=mkPill(stealRow,56);local on=false
		local function sv(s) on=s;animPill(pill,dot,s) end
		setInstaGrab=sv
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=5
		clk.Activated:Connect(function() on=not on;sv(on);Steal.AutoStealEnabled=on;Steal.StealDuration=1.3;if on then if not pcall(startAutoSteal) then Steal.AutoStealEnabled=false;sv(false) end else stopAutoSteal() end;saveConfig() end)
		pill.ZIndex=3;dot.ZIndex=4
	end
	do local row=mkRow(40);mkLabel(row,"Grab Radius");radInput=mkBox(row,Steal.StealRadius,64,72,function(v) if v>=0.5 and v<=300 then setCurrentStealRadius(v) else radInput.Text=tostring(Steal.StealRadius) end;saveConfig() end) end
	do
		local row=mkRow(28);stealRecommendation=Instance.new("TextLabel",row)
		stealRecommendation.Size=UDim2.new(1,-20,1,0);stealRecommendation.Position=UDim2.new(0,11,0,0)
		stealRecommendation.BackgroundTransparency=1;stealRecommendation.TextColor3=THEME_ACCENT
		stealRecommendation.Font=Enum.Font.GothamBold;stealRecommendation.TextSize=10;stealRecommendation.TextXAlignment=Enum.TextXAlignment.Left;stealRecommendation.ZIndex=8
		trackTheme(function(c) if stealRecommendation and stealRecommendation.Parent then stealRecommendation.TextColor3=c end end)
	end
	refreshStealTypeUi()

	mkSect("AIMBOT")
	do
		local row=mkRow(40);mkLabel(row,"Normal Aimbot")
		mkKB(row,KB.AutoBat,function(k,isGp) if isGp then KB.AutoBat.gp=k;KB.AutoBat.kb=nil else KB.AutoBat.kb=k;KB.AutoBat.gp=nil end;saveConfig() end)
	end
	do
		local adRow=mkRow(40);mkLabel(adRow,"Anti Desync Aimbot")
		mkKB(adRow,KB.AntiDesyncAutoBat,function(k,isGp) if isGp then KB.AntiDesyncAutoBat.gp=k;KB.AntiDesyncAutoBat.kb=nil else KB.AntiDesyncAutoBat.kb=k;KB.AntiDesyncAutoBat.gp=nil end;saveConfig() end)
	end
	setAutoSwingVisual=mkToggle("Auto Swing",function(on) autoSwingEnabled=on;saveConfig() end)
	if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
	do local row=mkRow(40);mkLabel(row,"Aimbot Speed");mkBox(row,aimbotSpeed,50,48,function(v) if v>0 and v<=200 then aimbotSpeed=v end;saveConfig() end) end
	do local row=mkRow(40);mkLabel(row,"Aimbot Lagger Speed");mkBox(row,aimbotLaggerSpeed,50,48,function(v) if v>0 and v<=200 then aimbotLaggerSpeed=v end;saveConfig() end) end
	autoBatSetVisual=function() end

	mkSect("Mechanics")
	setSafeModeVisual=mkToggle("Safe Mode",function(on) antiKickEnabled=on;if on then _akForceStop("SAFE MODE") end;saveConfig() end)
	if setSafeModeVisual then setSafeModeVisual(antiKickEnabled) end
	setInfJumpVisual=mkToggle("Infinite Jump",function(on) infJumpEnabled=on;saveConfig() end)
	setAntiRagVisual=mkToggle("Anti Ragdoll",function(on) antiRagdollEnabled=on;if on then startAntiRagdoll() else stopAntiRagdoll() end;saveConfig() end)
	setMedusaVisual=mkToggle("Medusa Counter",function(on) medusaCounterEnabled=on;if on then setupMedusa(LP.Character) else stopMedusaCounter() end;saveConfig() end)
	do setBatCounterVisual=mkToggle("Bat Counter",function(on) batCounterEnabled=on;if on then startBatCounter() else stopBatCounter() end;saveConfig() end) end
	setAutoResetVisual=mkToggle("Auto Reset on Med",function(on) autoResetEnabled=on;if on then startAutoReset(LP.Character) else stopAutoReset() end;saveConfig() end)
	do
		local row=mkRow(40);mkLabel(row,"Insta Reset")
		mkKB(row,KB.InstaReset,function(k,isGp)
			if isGp then KB.InstaReset.gp=k;KB.InstaReset.kb=nil else KB.InstaReset.kb=k;KB.InstaReset.gp=nil end
			saveConfig()
		end)
		local clk=Instance.new("TextButton",row)
		clk.Size=UDim2.new(0.58,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(cursedInstaReset)
	end
	do local row=mkRow(40);mkLabel(row,"Drop Brainrot");mkKB(row,KB.DropBrainrot,function(k,isGp) if isGp then KB.DropBrainrot.gp=k;KB.DropBrainrot.kb=nil else KB.DropBrainrot.kb=k;KB.DropBrainrot.gp=nil end;saveConfig() end);local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(0.58,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2;clk.Activated:Connect(function() runDrop() end) end

	mkSect("Teleport")
	setAutoTPVisual=mkToggle("Auto TP Down",function(on) autoTPEnabled=on;if on then startAutoTP() else stopAutoTP() end;saveConfig() end)
	do local row=mkRow(40);mkLabel(row,"TP Down Height");autoTPHeightBox=mkBox(row,autoTPHeight,50,56,function(v) if v>=0 and v<=500 then autoTPHeight=v else autoTPHeightBox.Text=tostring(autoTPHeight) end;saveConfig() end) end
	do local row=mkRow(40);mkLabel(row,"TP Down");mkKB(row,KB.TPFloor,function(k,isGp) if isGp then KB.TPFloor.gp=k;KB.TPFloor.kb=nil else KB.TPFloor.kb=k;KB.TPFloor.gp=nil end;saveConfig() end);local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(0.58,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2;clk.Activated:Connect(function() runTPFloor() end) end

	mkSect("Auto")
	do
		local row=mkRow(40);mkLabel(row,"Auto Left Key")
		mkKB(row,KB.AutoLeft,function(k,isGp) if isGp then KB.AutoLeft.gp=k;KB.AutoLeft.kb=nil else KB.AutoLeft.kb=k;KB.AutoLeft.gp=nil end;saveConfig() end)
		autoLeftSetVisual=function() end
	end
	do
		local row=mkRow(40);mkLabel(row,"Auto Right Key")
		mkKB(row,KB.AutoRight,function(k,isGp) if isGp then KB.AutoRight.gp=k;KB.AutoRight.kb=nil else KB.AutoRight.kb=k;KB.AutoRight.gp=nil end;saveConfig() end)
		autoRightSetVisual=function() end
	end

	mkSect("Visuals")
	do
		local row=mkRow(40);mkLabel(row,"Sky Theme")
		V.skyValLbl=Instance.new("TextLabel",row)
		V.skyValLbl.Size=UDim2.new(0,124,1,0);V.skyValLbl.Position=UDim2.new(1,-128,0,0)
		V.skyValLbl.BackgroundTransparency=1;V.skyValLbl.Text=V.skyTheme
		V.skyValLbl.TextColor3=THEME_ACCENT;V.skyValLbl.Font=Enum.Font.GothamBlack;V.skyValLbl.TextSize=11
		V.skyValLbl.TextXAlignment=Enum.TextXAlignment.Right;V.skyValLbl.ZIndex=8
		do local _skyLbl=V.skyValLbl; trackTheme(function(c) if _skyLbl and _skyLbl.Parent then _skyLbl.TextColor3 = c end end) end
		local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(function()
			if _anyKeyListening then return end
			local idx=1
			for i,name in ipairs(SKY_PRESETS_LIST) do if name==V.skyTheme then idx=i;break end end
			idx=(idx % #SKY_PRESETS_LIST) + 1
			applyCustomSky(SKY_PRESETS_LIST[idx])
			V.skyValLbl.Text=V.skyTheme
			saveConfig()
		end)
		V.setSkyVisual=function() if V.skyValLbl then V.skyValLbl.Text=V.skyTheme end end
	end
	setPlayerESPVisual=mkToggle("Player ESP",function(on) if on then startPlayerESP() else stopPlayerESP() end;saveConfig() end)
	do local row=mkRow(40);mkLabel(row,"Field of View");V.customFovBox=mkBox(row,V.customFovValue,64,72,function(v) if v>=30 and v<=120 then V.customFovValue=v;workspace.CurrentCamera.FieldOfView=v else V.customFovBox.Text=tostring(V.customFovValue) end;saveConfig() end) end
	setRagdollCountdownVisual=mkToggle("Ragdoll Countdown",function(on) ragdollCountdownEnabled=on;if not on then stopRagdollCountdown() end;saveConfig() end)
	setStretchRezVisual=mkToggle("FPS Boost",function(on) if on then enableStretchRez() else disableStretchRez() end;saveConfig() end)
	setAntiLagVisual=mkToggle("Anti Lag",function(on) if on then enableAntiLag() else disableAntiLag() end;saveConfig() end)
	setNoCamCollisionVisual=mkToggle("No Cam Collision",function(on) if on then enableNoCamCollision() else disableNoCamCollision() end;saveConfig() end)
	setUnwalkVisual=mkToggle("Unwalk",function(on) unwalkEnabled=on;if on then startUnwalk() else stopUnwalk() end;saveConfig() end)
	setHitHarderAnimVisual=mkToggle("Hit Harder Anim",function(on) hitHarderAnimEnabled=on;if on then enableHitHarderAnim() else disableHitHarderAnim() end;saveConfig() end)


	mkSect("GUI Settings")
	do
		local row=mkRow(40);mkLabel(row,"GUI Size")
		setGuiSizeVisual=mkSlider(row,guiSizeValue,0.75,1.35,0.05,function(v) guiSizeValue=v;applyGuiSize();saveConfig() end,"x")
	end
	setIntroVisual = mkToggle("Intro", function(on) _introEnabled = (on == true); if not _introEnabled then stopIntroPlayback();stopIntroPreview() end; saveConfig() end)
	if setIntroVisual then setIntroVisual(_introEnabled) end
	do
		local row=mkRow(40);mkLabel(row,"Intro Song")
		local btn=Instance.new("TextButton",row)
		btn.Size=UDim2.new(0.58,0,1,0);btn.Position=UDim2.new(0.42,0,0,0)
		btn.BackgroundColor3=THEME_ACCENT;btn.BorderSizePixel=0;btn.TextColor3=Color3.fromRGB(0,0,0)
		btn.Font=Enum.Font.GothamBold;btn.TextSize=13;btn.AutoButtonColor=false;btn.Text=getIntroSongName()
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
		trackTheme(function(c) if btn and btn.Parent then btn.BackgroundColor3=c; btn.TextColor3=Color3.fromRGB(0,0,0) end end)
		setIntroSongVisual=function()
			if btn and btn.Parent then btn.Text=getIntroSongName(); btn.TextColor3=Color3.fromRGB(0,0,0) end
		end
		btn.Activated:Connect(function()
			if _anyKeyListening then return end
			if #INTRO_MUSIC_OPTIONS <= 0 then
				if showActionNotification then showActionNotification("ADD SONG LINKS") end
				if setIntroSongVisual then setIntroSongVisual() end
				return
			end
			selectedIntroMusic=selectedIntroMusic+1
			if selectedIntroMusic>#INTRO_MUSIC_OPTIONS then selectedIntroMusic=1 end
			if setIntroSongVisual then setIntroSongVisual() end
			previewIntroMusic(selectedIntroMusic)
			saveConfig()
		end)
	end
	do local row=mkRow(40);mkLabel(row,"Hide GUI");mkKB(row,KB.GuiHide,function(k,isGp) if isGp then KB.GuiHide.gp=k;KB.GuiHide.kb=nil else KB.GuiHide.kb=k;KB.GuiHide.gp=nil end;saveConfig() end) end

	UIS.InputBegan:Connect(function(input,gpe)
		if _anyKeyListening then return end
		if input.UserInputType==Enum.UserInputType.Keyboard then
			if gpe or UIS:GetFocusedTextBox() then return end
		elseif not isGamepadInput(input) then return end
		if not isBindableInput(input) then return end
		local kc=input.KeyCode
		if kbMatch(KB.LaggerToggle,kc) then
			toggleLaggerMode()
			saveConfig()
		elseif kbMatch(KB.SpeedToggle,kc) then
			toggleCarryMode()
			saveConfig()
		elseif kbMatch(KB.DropBrainrot,kc) then runDrop()
		elseif kbMatch(KB.TPFloor,kc) then runTPFloor()
		elseif kbMatch(KB.InstaReset,kc) then cursedInstaReset()
		elseif kbMatch(KB.AutoLeft,kc) then
			if autoLeftEnabled then
				autoLeftEnabled=false;stopAutoLeft()
			else
				queueAutoLeftStart()
			end
			if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
		elseif kbMatch(KB.AutoRight,kc) then
			if autoRightEnabled then
				autoRightEnabled=false;stopAutoRight()
			else
				queueAutoRightStart()
			end
			if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
		elseif kbMatch(KB.AutoBat,kc) then
			if not autoBatEnabled then
				queueAutoBatStart()
				if autoBatSetVisual then autoBatSetVisual(autoBatEnabled) end
			else
				autoBatEnabled=false;disableAutoBat()
				if autoBatSetVisual then autoBatSetVisual(false) end
			end
		elseif kbMatch(KB.AntiDesyncAutoBat,kc) then
			if antiDesyncAutoBatEnabled then stopAntiDesyncAutoBat() else startAntiDesyncAutoBat() end
			saveConfig()
		elseif kbMatch(KB.GuiHide,kc) then if main.Visible then hideGui() else showGui() end
		end
	end)
	-- Mobile buttons removed by request.
	-- Ace Duels: CINEMATIC INTRO (8.0s) — spread-out flying ace cards, clean grey fade, title reveal
	local origSize = main.Size
	if not _introEnabled then
		stopIntroPlayback()
		stopIntroPreview()
		main.Size = origSize
	else
		playIntroMusic()
		main.Size = UDim2.new(0, 0, 0, 0)
		task.spawn(function()
			local introGui = Instance.new("ScreenGui", gui.Parent)
			introGui.Name = "AceDuelsIntro"
			introGui.IgnoreGuiInset = true
			introGui.DisplayOrder = 100
			introGui.ResetOnSpawn = false

			local darkBg = Instance.new("Frame", introGui)
			darkBg.Size = UDim2.new(1, 0, 1, 0)
			darkBg.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
			darkBg.BackgroundTransparency = 1
			darkBg.BorderSizePixel = 0
			darkBg.ZIndex = 1
			local bgGrad = Instance.new("UIGradient", darkBg)
			bgGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 42, 46)),
				ColorSequenceKeypoint.new(0.45, Color3.fromRGB(18, 18, 20)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 12))
			})
			bgGrad.Rotation = 90

			local redWash = Instance.new("Frame", introGui)
			redWash.Size = UDim2.new(1, 0, 1, 0)
			redWash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			redWash.BackgroundTransparency = 1
			redWash.BorderSizePixel = 0
			redWash.ZIndex = 2

			local vignetteTop = Instance.new("Frame", introGui)
			vignetteTop.Size = UDim2.new(1, 0, 0.18, 0)
			vignetteTop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			vignetteTop.BackgroundTransparency = 1
			vignetteTop.BorderSizePixel = 0
			vignetteTop.ZIndex = 3
			local vignetteBottom = Instance.new("Frame", introGui)
			vignetteBottom.Size = UDim2.new(1, 0, 0.18, 0)
			vignetteBottom.Position = UDim2.new(0, 0, 0.82, 0)
			vignetteBottom.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			vignetteBottom.BackgroundTransparency = 1
			vignetteBottom.BorderSizePixel = 0
			vignetteBottom.ZIndex = 3

			local function makeAceCard(parent, size, z)
				local card = Instance.new("Frame", parent)
				card.Size = UDim2.new(0, math.floor(size * 0.68), 0, size)
				card.AnchorPoint = Vector2.new(0.5, 0.5)
				card.BackgroundColor3 = Color3.fromRGB(238, 238, 232)
				card.BackgroundTransparency = 1
				card.BorderSizePixel = 0
				card.ZIndex = z or 6
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, math.max(8, math.floor(size * 0.08)))
				local stroke = Instance.new("UIStroke", card)
				stroke.Color = Color3.fromRGB(190, 190, 190)
				stroke.Thickness = 1
				stroke.Transparency = 1
				local grad = Instance.new("UIGradient", card)
				grad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(195,198,200))
				grad.Rotation = 125

				local a1 = Instance.new("TextLabel", card)
				a1.Size = UDim2.new(0.28, 0, 0.25, 0)
				a1.Position = UDim2.new(0.06, 0, 0.04, 0)
				a1.BackgroundTransparency = 1
				a1.Text = "A\n♠"
				a1.TextColor3 = Color3.fromRGB(0,0,0)
				a1.Font = Enum.Font.GothamBlack
				a1.TextScaled = true
				a1.TextTransparency = 1
				a1.ZIndex = (z or 6) + 1

				local suit = Instance.new("TextLabel", card)
				suit.Size = UDim2.new(0.62, 0, 0.52, 0)
				suit.Position = UDim2.new(0.19, 0, 0.25, 0)
				suit.BackgroundTransparency = 1
				suit.Text = "♠"
				suit.TextColor3 = Color3.fromRGB(0,0,0)
				suit.Font = Enum.Font.GothamBlack
				suit.TextScaled = true
				suit.TextTransparency = 1
				suit.ZIndex = (z or 6) + 1

				local a2 = Instance.new("TextLabel", card)
				a2.Size = UDim2.new(0.28, 0, 0.25, 0)
				a2.Position = UDim2.new(0.66, 0, 0.71, 0)
				a2.BackgroundTransparency = 1
				a2.Text = "A\n♠"
				a2.TextColor3 = Color3.fromRGB(0,0,0)
				a2.Font = Enum.Font.GothamBlack
				a2.TextScaled = true
				a2.TextTransparency = 1
				a2.Rotation = 180
				a2.ZIndex = (z or 6) + 1
				return card, {a1, suit, a2}, stroke
			end

			local cards = {}
			for i = 1, 24 do
				local size = math.random(46, 108)
				local card, labels, stroke = makeAceCard(introGui, size, 5 + i)
				local side = (i % 2 == 0) and -0.35 or 1.35
				local targetSide = (i % 2 == 0) and 1.35 or -0.35
				local y = math.random(4, 96) / 100
				card.Position = UDim2.new(side, 0, y, 0)
				card.Rotation = math.random(-40, 40)
				cards[i] = {
					frame = card,
					labels = labels,
					stroke = stroke,
					startX = side,
					endX = targetSide,
					y = y,
					speed = 0.09 + math.random() * 0.10,
					bob = math.random() * 6.28,
					rot = math.random(-55, 55),
					drift = math.random(-14, 14) / 100
				}
			end

			local aceLogo, aceLabels, aceStroke = makeAceCard(introGui, 170, 25)
			aceLogo.Position = UDim2.new(0.5, 0, -0.35, 0)
			aceLogo.Rotation = -12

			local introActive = true
			local t = 0
			local driftConn = RunService.Heartbeat:Connect(function(dt)
				if not introActive then return end
				t = t + dt
				for _, cd in ipairs(cards) do
					local currentX = cd.frame.Position.X.Scale
					local dir = cd.startX < cd.endX and 1 or -1
					local newX = currentX + dir * cd.speed * dt
					if (dir == 1 and newX > 1.40) or (dir == -1 and newX < -0.40) then
						newX = cd.startX
					end
					local newY = math.clamp(cd.y + math.sin(t * 1.5 + cd.bob) * 0.035 + cd.drift, -0.08, 1.08)
					cd.frame.Position = UDim2.new(newX, 0, newY, 0)
					cd.frame.Rotation = cd.rot + math.sin(t * 2.5 + cd.bob) * 14
				end
			end)

			local center = Instance.new("Frame", introGui)
			center.AnchorPoint = Vector2.new(0.5, 0.5)
			center.Position = UDim2.new(0.5, 0, 0.5, 0)
			center.Size = UDim2.new(0, 660, 0, 250)
			center.BackgroundTransparency = 1
			center.ZIndex = 40

			local lineTop = Instance.new("Frame", center)
			lineTop.AnchorPoint = Vector2.new(0.5, 0)
			lineTop.Position = UDim2.new(0.5, 0, 0, 58)
			lineTop.Size = UDim2.new(0, 0, 0, 2)
			lineTop.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
			lineTop.BorderSizePixel = 0
			lineTop.ZIndex = 41
			local lineBot = Instance.new("Frame", center)
			lineBot.AnchorPoint = Vector2.new(0.5, 1)
			lineBot.Position = UDim2.new(0.5, 0, 1, -8)
			lineBot.Size = UDim2.new(0, 0, 0, 2)
			lineBot.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
			lineBot.BorderSizePixel = 0
			lineBot.ZIndex = 41

			local titleShadow = Instance.new("TextLabel", center)
			titleShadow.Size = UDim2.new(1, 0, 0, 86)
			titleShadow.Position = UDim2.new(0, 4, 0, 83)
			titleShadow.BackgroundTransparency = 1
			titleShadow.Text = "ACE DUELS"
			titleShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
			titleShadow.Font = Enum.Font.GothamBlack
			titleShadow.TextSize = 72
			titleShadow.TextTransparency = 1
			titleShadow.TextStrokeTransparency = 1
			titleShadow.ZIndex = 42

			local title = Instance.new("TextLabel", center)
			title.Size = UDim2.new(1, 0, 0, 86)
			title.Position = UDim2.new(0, 0, 0, 78)
			title.BackgroundTransparency = 1
			title.Text = "ACE DUELS"
			title.TextColor3 = Color3.fromRGB(245, 245, 245)
			title.Font = Enum.Font.GothamBlack
			title.TextSize = 72
			title.TextTransparency = 1
			title.TextStrokeTransparency = 1
			title.TextStrokeColor3 = Color3.fromRGB(35, 35, 35)
			title.ZIndex = 43

			local subtitle = Instance.new("TextLabel", center)
			subtitle.Size = UDim2.new(1, 0, 0, 26)
			subtitle.Position = UDim2.new(0, 0, 0, 169)
			subtitle.BackgroundTransparency = 1
			subtitle.Text = "Eugene"
			subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
			subtitle.Font = Enum.Font.GothamMedium
			subtitle.TextSize = 19
			subtitle.TextTransparency = 1
			subtitle.ZIndex = 43

			TS:Create(darkBg, TweenInfo.new(0.65), {BackgroundTransparency = 0.22}):Play()
			redWash.BackgroundTransparency = 1
			for _, cd in ipairs(cards) do
				task.delay(math.random() * 0.9, function()
					TS:Create(cd.frame, TweenInfo.new(0.65), {BackgroundTransparency = 0.08}):Play()
					if cd.stroke then TS:Create(cd.stroke, TweenInfo.new(0.65), {Transparency = 0.25}):Play() end
					for _, lbl in ipairs(cd.labels) do TS:Create(lbl, TweenInfo.new(0.65), {TextTransparency = 0}):Play() end
				end)
			end
			task.wait(0.85)

			TS:Create(aceLogo, TweenInfo.new(1.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.20, 0), BackgroundTransparency = 0.02, Rotation = 8}):Play()
			if aceStroke then TS:Create(aceStroke, TweenInfo.new(0.55), {Transparency = 0.15}):Play() end
			for _, lbl in ipairs(aceLabels) do TS:Create(lbl, TweenInfo.new(0.55), {TextTransparency = 0}):Play() end
			task.wait(1.05)

			TS:Create(lineTop, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 2), BackgroundColor3 = Color3.fromRGB(225, 225, 225)}):Play()
			TS:Create(lineBot, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 2), BackgroundColor3 = Color3.fromRGB(225, 225, 225)}):Play()
			task.wait(0.12)
			TS:Create(titleShadow, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.35, TextStrokeTransparency = 1}):Play()
			TS:Create(title, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0, TextStrokeTransparency = 0.18}):Play()
			task.wait(0.42)
			TS:Create(subtitle, TweenInfo.new(0.42), {TextTransparency = 0}):Play()

			for i = 1, 3 do
				TS:Create(title, TweenInfo.new(0.06), {TextColor3 = Color3.fromRGB(185, 185, 185)}):Play()
				redWash.BackgroundTransparency = 1
				task.wait(0.06)
				TS:Create(title, TweenInfo.new(0.06), {TextColor3 = Color3.fromRGB(245, 245, 245)}):Play()
				redWash.BackgroundTransparency = 1
				task.wait(0.06)
			end
			task.wait(3.05)

			TS:Create(center, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			TS:Create(title, TweenInfo.new(0.36), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			TS:Create(titleShadow, TweenInfo.new(0.36), {TextTransparency = 1}):Play()
			TS:Create(subtitle, TweenInfo.new(0.32), {TextTransparency = 1}):Play()
			TS:Create(lineTop, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 2)}):Play()
			TS:Create(lineBot, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 2)}):Play()
			TS:Create(aceLogo, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, 0, 1.25, 0), BackgroundTransparency = 1, Rotation = 28}):Play()
			for _, lbl in ipairs(aceLabels) do TS:Create(lbl, TweenInfo.new(0.45), {TextTransparency = 1}):Play() end
			if aceStroke then TS:Create(aceStroke, TweenInfo.new(0.45), {Transparency = 1}):Play() end
			TS:Create(darkBg, TweenInfo.new(0.75), {BackgroundTransparency = 1}):Play()
			redWash.BackgroundTransparency = 1
			for _, cd in ipairs(cards) do
				TS:Create(cd.frame, TweenInfo.new(0.55), {BackgroundTransparency = 1}):Play()
				if cd.stroke then TS:Create(cd.stroke, TweenInfo.new(0.55), {Transparency = 1}):Play() end
				for _, lbl in ipairs(cd.labels) do TS:Create(lbl, TweenInfo.new(0.55), {TextTransparency = 1}):Play() end
			end
			TS:Create(main, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = origSize}):Play()
			task.wait(0.9)
			introActive = false
			pcall(function() driftConn:Disconnect() end)
			pcall(function() introGui:Destroy() end)
		end)
	end
end
_savedCfg = nil
function loadConfigKeys()
	if not isfile then return end
	local cfgFile = isfile("AceDuels.json") and "AceDuels.json" or (isfile("Tooze.json") and "Tooze.json" or nil)
	if not cfgFile then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(readfile(cfgFile)) end)
	if not ok or not cfg then return end
	_savedCfg=cfg
	-- Migrate old Tooze save to AceDuels so the save file name is correct going forward.
	if cfgFile == "Tooze.json" and writefile then
		pcall(function() writefile("AceDuels.json", HS:JSONEncode(cfg)) end)
	end
	local function lk(e,d) if type(d)~="table" then return end;if d.kb and Enum.KeyCode[d.kb] then e.kb=Enum.KeyCode[d.kb] end;if d.gp and Enum.KeyCode[d.gp] then e.gp=Enum.KeyCode[d.gp] end end
	lk(KB.DropBrainrot,cfg.dropBrainrotKey);lk(KB.AutoLeft,cfg.autoLeftKey);lk(KB.AutoRight,cfg.autoRightKey)
	lk(KB.AutoBat,cfg.autoBatKey);lk(KB.AntiDesyncAutoBat,cfg.antiDesyncAutoBatKey);lk(KB.LaggerToggle,cfg.laggerToggleKey)
	lk(KB.TPFloor,cfg.tpFloorKey);lk(KB.InstaReset,cfg.instaResetKey);lk(KB.GuiHide,cfg.guiHideKey);lk(KB.SpeedToggle,cfg.speedToggleKey)
	if cfg.normalSpeed then NS=cfg.normalSpeed end
	if cfg.carrySpeed then CS=cfg.carrySpeed end
	if cfg.normalAutoStealRadius and type(cfg.normalAutoStealRadius)=="number" then
		Steal.NormalRadius=cfg.normalAutoStealRadius
	elseif cfg.grabRadius and type(cfg.grabRadius)=="number" then
		Steal.NormalRadius=cfg.grabRadius
	else Steal.NormalRadius=60 end
	if cfg.semiInstantStealRadius and type(cfg.semiInstantStealRadius)=="number" then Steal.SemiRadius=cfg.semiInstantStealRadius else Steal.SemiRadius=9 end
	Steal.StealMode=(cfg.stealMode=="Semi") and "Semi" or "Normal"
	setStealMode(Steal.StealMode)
	Steal.StealDuration=1.3
	if cfg.laggerSpeed and type(cfg.laggerSpeed)=="number" then LAGGER_SPEED=cfg.laggerSpeed end
	if cfg.laggerCarrySpeed and type(cfg.laggerCarrySpeed)=="number" then LAGGER_CARRY_SPEED=cfg.laggerCarrySpeed end
	if cfg.autoTPHeight and type(cfg.autoTPHeight)=="number" then autoTPHeight=cfg.autoTPHeight end
	-- Load these before the GUI is built so the Aimbot Speed boxes show the saved values.
	if cfg.aimbotSpeed and type(cfg.aimbotSpeed)=="number" and cfg.aimbotSpeed > 0 and cfg.aimbotSpeed <= 200 then
		aimbotSpeed=cfg.aimbotSpeed
	elseif cfg.batSpeed and type(cfg.batSpeed)=="number" and cfg.batSpeed > 0 and cfg.batSpeed <= 200 then
		aimbotSpeed=cfg.batSpeed
	end
	if cfg.aimbotLaggerSpeed and type(cfg.aimbotLaggerSpeed)=="number" and cfg.aimbotLaggerSpeed > 0 and cfg.aimbotLaggerSpeed <= 200 then
		aimbotLaggerSpeed=cfg.aimbotLaggerSpeed
	end
	if cfg.autoSwing~=nil then autoSwingEnabled=cfg.autoSwing==true end
	if cfg.introEnabled ~= nil then _introEnabled=cfg.introEnabled==true end
	if cfg.selectedIntroMusic and INTRO_MUSIC_OPTIONS[cfg.selectedIntroMusic] then selectedIntroMusic=cfg.selectedIntroMusic end
	if cfg.customFovValue and type(cfg.customFovValue)=="number" then V.customFovValue=cfg.customFovValue end
	if cfg.guiSize and type(cfg.guiSize)=="number" then guiSizeValue=math.clamp(cfg.guiSize,0.75,1.35) end
end
function loadConfigState()
	local cfg=_savedCfg;if not cfg then return end
	if normalBox then normalBox.Text=tostring(NS) end
	if carryBox then carryBox.Text=tostring(CS) end
	if radInput then radInput.Text=tostring(Steal.StealRadius) end
		if progressRadLbl then progressRadLbl.Text=string.format("Radius: %.2g",Steal.StealRadius) end
	if laggerBox then laggerBox.Text=tostring(LAGGER_SPEED) end
	if laggerCarryBox then laggerCarryBox.Text=tostring(LAGGER_CARRY_SPEED) end
	if autoTPHeightBox then autoTPHeightBox.Text=tostring(autoTPHeight) end
	if V.customFovBox then V.customFovBox.Text=tostring(V.customFovValue) end
	applyGuiSize()
	if setGuiSizeVisual then setGuiSizeVisual(guiSizeValue,false) end
	task.spawn(function()
		task.wait(0.15)
		if cfg.antiRagdoll then antiRagdollEnabled=true;if setAntiRagVisual then setAntiRagVisual(true) end;startAntiRagdoll() end
		if cfg.ragdollCountdown then ragdollCountdownEnabled=true;if setRagdollCountdownVisual then setRagdollCountdownVisual(true) end;hookRagdollCountdown(LP.Character) end
		if cfg.autoStealEnabled then Steal.StealDuration=1.3;Steal.AutoStealEnabled=true;if setInstaGrab then setInstaGrab(true) end;pcall(startAutoSteal) end
		if cfg.infiniteJump then infJumpEnabled=true;if setInfJumpVisual then setInfJumpVisual(true) end end
		if cfg.medusaCounter then medusaCounterEnabled=true;if setMedusaVisual then setMedusaVisual(true) end;setupMedusa(LP.Character) end
		if cfg.autoReset then autoResetEnabled=true;if setAutoResetVisual then setAutoResetVisual(true) end;startAutoReset(LP.Character) end
		if cfg.batCounter then batCounterEnabled=true;if setBatCounterVisual then setBatCounterVisual(true) end;startBatCounter() end
		if cfg.laggerMode then laggerToggled=true;speedMode=false;laggerPhase=cfg.laggerCarryMode and 2 or 1;refreshSpeedModeLabel()
		elseif cfg.carryMode then speedMode=false;toggleCarryMode() end
		if cfg.autoTPEnabled then autoTPEnabled=true;if setAutoTPVisual then setAutoTPVisual(true) end;startAutoTP() end
		if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
		if cfg.aimbotSpeed and cfg.aimbotSpeed > 0 and cfg.aimbotSpeed <= 200 then aimbotSpeed=cfg.aimbotSpeed elseif cfg.batSpeed and cfg.batSpeed > 0 and cfg.batSpeed <= 200 then aimbotSpeed=cfg.batSpeed end
		if cfg.aimbotLaggerSpeed and cfg.aimbotLaggerSpeed > 0 and cfg.aimbotLaggerSpeed <= 200 then aimbotLaggerSpeed=cfg.aimbotLaggerSpeed end
		if cfg.safeMode ~= nil then antiKickEnabled = cfg.safeMode == true end
		if setSafeModeVisual then setSafeModeVisual(antiKickEnabled) end
		autoBatEnabled=false;if autoBatSetVisual then autoBatSetVisual(false) end
		antiDesyncAutoBatEnabled=false;if setAntiDesyncAutoBatVisual then setAntiDesyncAutoBatVisual(false) end
		if cfg.unwalkEnabled then unwalkEnabled=true;if setUnwalkVisual then setUnwalkVisual(true) end;task.spawn(function() task.wait(0.5);startUnwalk() end) end
		if cfg.hitHarderAnim then hitHarderAnimEnabled=true;if setHitHarderAnimVisual then setHitHarderAnimVisual(true) end;enableHitHarderAnim() end
		if cfg.antiLag then enableAntiLag();if setAntiLagVisual then setAntiLagVisual(true) end end
		if cfg.stretchRez then enableStretchRez();if setStretchRezVisual then setStretchRezVisual(true) end end
		if cfg.noCamCollision then enableNoCamCollision();if setNoCamCollisionVisual then setNoCamCollisionVisual(true) end end
		if cfg.customFov then enableCustomFov();if V.setCustomFovVisual then V.setCustomFovVisual(true) end end
		if cfg.skyTheme and SKY_PRESETS[cfg.skyTheme] then applyCustomSky(cfg.skyTheme);if V.setSkyVisual then V.setSkyVisual() end end
		if cfg.ultraMode then enableUltraMode();if V.setUltraModeVisual then V.setUltraModeVisual(true) end end
		if cfg.removeAccessories then enableRemoveAccessories();if V.setRemoveAccVisual then V.setRemoveAccVisual(true) end end
		if cfg.customFontEnabled then task.spawn(function() task.wait(1);enableCustomFont() end);if V.setCustomFontVisual then V.setCustomFontVisual(true) end end
		if cfg.potatoGraphics then enablePotatoGraphics();if V.setPotatoVisual then V.setPotatoVisual(true) end end
		if cfg.autoSave ~= nil then V.autoSaveEnabled=cfg.autoSave end  -- legacy field — auto-save is now always-on
		if cfg.lockGui ~= nil then _guiLocked=cfg.lockGui==true; if setLockGuiVisual then setLockGuiVisual(_guiLocked) end end
		if cfg.introEnabled ~= nil then _introEnabled=cfg.introEnabled==true; if setIntroVisual then setIntroVisual(_introEnabled) end end
		if cfg.selectedIntroMusic and INTRO_MUSIC_OPTIONS[cfg.selectedIntroMusic] then selectedIntroMusic=cfg.selectedIntroMusic;if setIntroSongVisual then setIntroSongVisual() end end
		if cfg.themeAccent and type(cfg.themeAccent)=="table" and #cfg.themeAccent==3 then
			pcall(function() if setAccent_global then setAccent_global(Color3.new(cfg.themeAccent[1], cfg.themeAccent[2], cfg.themeAccent[3])) end end)
		end
		if cfg.sidebarArt and type(cfg.sidebarArt)=="string" then
			if cfg.sidebarArt == "" then cfg.sidebarArt = DEFAULT_SIDEBAR_ART_ID end
			if cfg.sidebarArt == "72407991565941" or cfg.sidebarArt == "132686352867687" or cfg.sidebarArt == "111817612356516" or cfg.sidebarArt == "115117078011241" or cfg.sidebarArt == "105485901922617" or cfg.sidebarArt == "91898908777425" then cfg.sidebarArt = DEFAULT_SIDEBAR_ART_ID end
			pcall(function() if setSidebarArt_global then setSidebarArt_global(cfg.sidebarArt) end end)
		else
			pcall(function() if setSidebarArt_global then setSidebarArt_global(DEFAULT_SIDEBAR_ART_ID) end end)
		end
		if cfg.playerESP then
			pcall(function() startPlayerESP(); if setPlayerESPVisual then setPlayerESPVisual(true) end end)
		end
	end)
end
loadConfigKeys()
buildGui()
loadConfigState()
print("Ace Duels Loaded")
