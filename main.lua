-- =======================================================
-- MÓDULO DE PROTEÇÃO ANTI-BAN & METAMETHOD SPOOFING
-- =======================================================
local SuccessSpoof, ErrorSpoof = pcall(function()
    local RawMeta = getrawmetatable(game)
    local OldIndex = RawMeta.__index
    local OldNamecall = RawMeta.__namecall
    setreadonly(RawMeta, false)

    RawMeta.__index = newcclosure(function(Self, Key)
        if not checkcaller() and Self:IsA("Humanoid") then
            if Key == "WalkSpeed" then return 16
            elseif Key == "JumpPower" or Key == "JumpHeight" then return 50 end
        end
        return OldIndex(Self, Key)
    end)

    RawMeta.__namecall = newcclosure(function(Self, ...)
        local Method = getnamecallmethod()
        if not checkcaller() and Method == "Kick" then
            warn("⚠️ [Anti-Ban] Tentativa de Kick do servidor bloqueada!")
            return nil
        end
        return OldNamecall(Self, ...)
    end)

    setreadonly(RawMeta, true)
end)

-- =======================================================
-- INTERFACE RAYFIELD UI & LÓGICA PRINCIPAL
-- =======================================================
local Success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not Success or not Rayfield then warn("Falha ao carregar UI.") return end

local Window = Rayfield:CreateWindow({
   Name = "Zeta Shift - Universal Edition",
   LoadingTitle = "Inicializando Zeta Shift...",
   LoadingSubtitle = "Otimizado para Delta Executor",
   ConfigurationSaving = { Enabled = false }
})

-- Serviços do Roblox
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Stats = game:GetService("Stats")

-- Variaveis de Combate
local AimbotEnabled = false
local SilentAimEnabled = false
local TargetPart = "Cabeça"
local Smoothness = 0.2
local TeamCheck = true
local WallCheck = false
local HitSoundEnabled = false

-- Variaveis de Movimentação
local WalkSpeedValue = 16
local SpeedHackEnabled = false
local JumpPowerValue = 50
local JumpPowerEnabled = false
local InfiniteJumpEnabled = false
local NoclipEnabled = false
local FlyEnabled = false
local FlySpeed = 50
local AirWalkEnabled = false
local AirWalkPlatform = nil
local SpinbotEnabled = false
local SpinbotSpeed = 20

-- Variaveis Visuais & Chams
local ESPBoxEnabled = false
local ESPNameEnabled = false
local ESPHealthEnabled = false
local ESPTracersEnabled = false
local ChamsEnabled = false
local ChamsColor = Color3.fromRGB(255, 0, 100)
local CrosshairEnabled = false

-- FOV & Utilitarios
local ShowFOV = true
local BaseFOVRadius = 120
local CurrentFOVRadius = 120
local SelectedPlayerTP = ""
local ChatSpammerEnabled = false
local ChatSpammerMessage = "Zeta Shift em execução!"
local ChatSpammerDelay = 5

-- Desenho do Crosshair
local CrosshairVertical = Drawing.new("Line")
local CrosshairHorizontal = Drawing.new("Line")
CrosshairVertical.Thickness = 1.5
CrosshairVertical.Color = Color3.fromRGB(0, 255, 150)
CrosshairHorizontal.Thickness = 1.5
CrosshairHorizontal.Color = Color3.fromRGB(0, 255, 150)

-- Stats (FPS & Ping Display)
local StatsText = Drawing.new("Text")
StatsText.Size = 14
StatsText.Outline = true
StatsText.Color = Color3.fromRGB(0, 255, 200)
StatsText.Position = Vector2.new(10, 10)
StatsText.Visible = true

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Transparency = 1

local ESPDrawings = {}
local Highlights = {}

-- Som de Hit
local HitSound = Instance.new("Sound")
HitSound.SoundId = "rbxassetid://160432334"
HitSound.Volume = 2
HitSound.Parent = SoundService

-- Criar Abas
local CombatTab = Window:CreateTab("Combate", 4483362458)
local VisualsTab = Window:CreateTab("Visuais & Chams", 4483362458)
local PlayerTab = Window:CreateTab("Jogador & Movimento", 4483362458)
local UtilityTab = Window:CreateTab("Utilitários & Server", 4483362458)

-- Função Adaptativa para Partes
local function GetPart(character, partName)
   if not character then return nil end
   if partName == "Cabeça" then return character:FindFirstChild("Head")
   elseif partName == "Torso" then return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") end
   return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

-- Busca de Alvo Proximo
local function GetBestTarget()
   local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
   local ClosestTarget = nil
   local ShortestDistance = CurrentFOVRadius

   for _, player in pairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and player.Character then
         local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
         local Part = GetPart(player.Character, TargetPart)

         if Part and humanoid and humanoid.Health > 0 then
            if not TeamCheck or (player.Team ~= LocalPlayer.Team or player.Team == nil) then
               local PartPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
               if OnScreen then
                  local Distance = (Vector2.new(PartPos.X, PartPos.Y) - CenterScreen).Magnitude
                  if Distance < ShortestDistance then
                     ShortestDistance = Distance
                     ClosestTarget = Part
                  end
               end
            end
         end
      end
   end
   return ClosestTarget
end

-- COMBATE
CombatTab:CreateSection("Aimbot & Silent Aim")
CombatTab:CreateToggle({ Name = "Ativar Aimbot (Câmera)", CurrentValue = false, Callback = function(V) AimbotEnabled = V end })
CombatTab:CreateToggle({ Name = "Ativar Silent Aim (Mira Invisível)", CurrentValue = false, Callback = function(V) SilentAimEnabled = V end })
CombatTab:CreateDropdown({ Name = "Parte Alvo", Options = {"Cabeça", "Torso"}, CurrentOption = {"Cabeça"}, MultipleOptions = false, Callback = function(O) TargetPart = O[1] end })
CombatTab:CreateToggle({ Name = "Som ao Acertar Tiro (Hit Sound)", CurrentValue = false, Callback = function(V) HitSoundEnabled = V end })
CombatTab:CreateToggle({ Name = "Team Check", CurrentValue = true, Callback = function(V) TeamCheck = V end })

-- VISUAIS
VisualsTab:CreateSection("ESP & Chams")
VisualsTab:CreateToggle({ Name = "ESP Box (Caixas)", CurrentValue = false, Callback = function(V) ESPBoxEnabled = V end })
VisualsTab:CreateToggle({ Name = "ESP Nome", CurrentValue = false, Callback = function(V) ESPNameEnabled = V end })
VisualsTab:CreateToggle({ Name = "ESP Barra de Vida Colorida", CurrentValue = false, Callback = function(V) ESPHealthEnabled = V end })
VisualsTab:CreateToggle({ Name = "ESP Tracers", CurrentValue = false, Callback = function(V) ESPTracersEnabled = V end })
VisualsTab:CreateToggle({ Name = "Chams (Brilho Através da Parede)", CurrentValue = false, Callback = function(V) ChamsEnabled = V end })
VisualsTab:CreateToggle({ Name = "Crosshair Personalizado", CurrentValue = false, Callback = function(V) CrosshairEnabled = V end })

VisualsTab:CreateSection("Ajustes de FOV")
VisualsTab:CreateToggle({ Name = "Mostrar Círculo do FOV", CurrentValue = true, Callback = function(V) ShowFOV = V end })
VisualsTab:CreateSlider({ Name = "Tamanho do FOV", Range = {50, 400}, Increment = 5, Suffix = "px", CurrentValue = 120, Callback = function(V) BaseFOVRadius = V CurrentFOVRadius = V end })

-- JOGADOR & MOVIMENTO
PlayerTab:CreateSection("Modificadores de Personagem")
PlayerTab:CreateToggle({ Name = "Ativar Velocidade Alterada", CurrentValue = false, Callback = function(V) SpeedHackEnabled = V end })
PlayerTab:CreateSlider({ Name = "Velocidade", Range = {16, 250}, Increment = 1, CurrentValue = 16, Callback = function(V) WalkSpeedValue = V end })
PlayerTab:CreateToggle({ Name = "Ativar Pulo Alterado", CurrentValue = false, Callback = function(V) JumpPowerEnabled = V end })
PlayerTab:CreateSlider({ Name = "Força do Pulo", Range = {50, 300}, Increment = 5, CurrentValue = 50, Callback = function(V) JumpPowerValue = V end })

PlayerTab:CreateSection("Habilidades Especiais")
PlayerTab:CreateToggle({ Name = "Voar (Fly)", CurrentValue = false, Callback = function(V) FlyEnabled = V end })
PlayerTab:CreateSlider({ Name = "Velocidade do Voar", Range = {10, 200}, Increment = 5, CurrentValue = 50, Callback = function(V) FlySpeed = V end })
PlayerTab:CreateToggle({ Name = "Andar no Ar (Air Walk)", CurrentValue = false, Callback = function(V) AirWalkEnabled = V end })
PlayerTab:CreateToggle({ Name = "Pulo Infinito", CurrentValue = false, Callback = function(V) InfiniteJumpEnabled = V end })
PlayerTab:CreateToggle({ Name = "Noclip (Atravessar Paredes)", CurrentValue = false, Callback = function(V) NoclipEnabled = V end })
PlayerTab:CreateToggle({ Name = "Spinbot (Girar Rápido)", CurrentValue = false, Callback = function(V) SpinbotEnabled = V end })

PlayerTab:CreateSection("Teleporte")
PlayerTab:CreateButton({
   Name = "Atualizar Lista de Jogadores",
   Callback = function()
      local plrs = {}
      for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(plrs, p.Name) end end
      -- Atualiza lista
   end,
})
PlayerTab:CreateButton({
   Name = "Teleportar para Alvo Selecionado",
   Callback = function()
      if SelectedPlayerTP ~= "" and Players:FindFirstChild(SelectedPlayerTP) then
         local TargetChar = Players[SelectedPlayerTP].Character
         if TargetChar and TargetChar:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            LocalPlayer.Character:SetPrimaryPartCFrame(TargetChar.HumanoidRootPart.CFrame)
         end
      end
   end,
})

-- UTILITÁRIOS & DESEMPENHO
UtilityTab:CreateSection("Otimização & Servidor")
UtilityTab:CreateButton({
   Name = "Aumentar FPS (FPS Booster / Low Graphics)",
   Callback = function()
      for _, v in pairs(game:GetDescendants()) do
         if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
         elseif v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()
         end
      end
      Rayfield:Notify({ Title = "FPS Booster", Content = "Gráficos otimizados com sucesso!", Duration = 3 })
   end,
})

UtilityTab:CreateButton({
   Name = "Server Hop (Poucos Jogadores)",
   Callback = function()
      pcall(function()
         local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
         for _, s in pairs(servers) do
            if s.id ~= game.JobId and s.playing < 5 then
               TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
               break
            end
         end
      end)
   end,
})

UtilityTab:CreateSection("Chat Spammer")
UtilityTab:CreateToggle({ Name = "Ativar Spammer de Chat", CurrentValue = false, Callback = function(V) ChatSpammerEnabled = V end })

-- Thread do Chat Spammer
task.spawn(function()
   while task.wait(ChatSpammerDelay) do
      if ChatSpammerEnabled then
         pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
               TextChatService.TextChannels.RBXGeneral:SendAsync(ChatSpammerMessage)
            else
               ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(ChatSpammerMessage, "All")
            end
         end)
      end
   end
end)

-- Pulo Infinito
UserInputService.JumpRequest:Connect(function()
   if InfiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
      LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
   end
end)

-- LOOP PRINCIPAL (RENDERSTEPPED)
RunService.RenderStepped:Connect(function()
   -- FOV
   local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
   FOVCircle.Position = CenterScreen
   FOVCircle.Radius = CurrentFOVRadius
   FOVCircle.Visible = ShowFOV

   -- FPS & Ping Display
   local fps = math.floor(1 / RunService.RenderStepped:Wait())
   local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
   StatsText.Text = "FPS: " .. tostring(fps) .. " | Ping: " .. tostring(ping) .. "ms"

   -- Crosshair Customizado
   if CrosshairEnabled then
      CrosshairVertical.From = Vector2.new(CenterScreen.X, CenterScreen.Y - 10)
      CrosshairVertical.To = Vector2.new(CenterScreen.X, CenterScreen.Y + 10)
      CrosshairHorizontal.From = Vector2.new(CenterScreen.X - 10, CenterScreen.Y)
      CrosshairHorizontal.To = Vector2.new(CenterScreen.X + 10, CenterScreen.Y)
      CrosshairVertical.Visible = true
      CrosshairHorizontal.Visible = true
   else
      CrosshairVertical.Visible = false
      CrosshairHorizontal.Visible = false
   end

   -- Movimentação (Speed & Jump)
   if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
      local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
      if SpeedHackEnabled then Hum.WalkSpeed = WalkSpeedValue end
      if JumpPowerEnabled then Hum.UseJumpPower = true Hum.JumpPower = JumpPowerValue end
   end

   -- Noclip
   if NoclipEnabled and LocalPlayer.Character then
      for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
         if part:IsA("BasePart") then part.CanCollide = false end
      end
   end

   -- Spinbot
   if SpinbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
      LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(SpinbotSpeed), 0)
   end

   -- Air Walk (Plataforma Invisível)
   if AirWalkEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
      if not AirWalkPlatform or not AirWalkPlatform.Parent then
         AirWalkPlatform = Instance.new("Part", workspace)
         AirWalkPlatform.Size = Vector3.new(6, 1, 6)
         AirWalkPlatform.Transparency = 1
         AirWalkPlatform.Anchored = true
      end
      AirWalkPlatform.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3.5, 0)
   elseif AirWalkPlatform me
      AirWalkPlatform:Destroy()
      AirWalkPlatform = nil
   end

   -- Voo (Fly)
   if FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
      local HRP = LocalPlayer.Character.HumanoidRootPart
      local moveVec = Camera.CFrame.LookVector * (FlySpeed / 10)
      HRP.Velocity = Vector3.new(moveVec.X, 0, moveVec.Z)
   end

   -- Aimbot de Câmera
   if AimbotEnabled then
      local TargetInst = GetBestTarget()
      if TargetInst then
         Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, TargetInst.Position), Smoothness)
         if HitSoundEnabled and not HitSound.IsPlaying then HitSound:Play() end
      end
   end

   -- ESP & Chams Updater
   for _, player in pairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and player.Character then
         local Char = player.Character
         local Hum = Char:FindFirstChildOfClass("Humanoid")
         local HRP = Char:FindFirstChild("HumanoidRootPart")

         -- Chams (Highlight)
         if ChamsEnabled then
            if not Highlights[player] then
               local hl = Instance.new("Highlight")
               hl.Parent = Char
               hl.FillColor = ChamsColor
               hl.OutlineColor = Color3.fromRGB(255, 255, 255)
               Highlights[player] = hl
            end
         elseif Highlights[player] then
            Highlights[player]:Destroy()
            Highlights[player] = nil
         end
      end
   end
end)
