local json = require("json")
local mod = RegisterMod("chargedkeys", 1)

local Settings = { key = Keyboard.KEY_LEFT_SHIFT }

local function index(player)
    local item
    if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
        item = 2
    else
        item = 1
    end
    return tostring(player:GetCollectibleRNG(item):GetSeed())
end

local keyboard_player
local reset_charge = {}

function mod:OnUseItem(type, rng, player, use_flags, active_slot)
    if index(player) == keyboard_player then
        if active_slot == ActiveSlot.SLOT_POCKET
            and Input.IsActionPressed(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
            and not Input.IsButtonPressed(Settings.key, player.ControllerIndex)
        then
            reset_charge[index(player)] = true
            return true
        end
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, mod.OnUseItem)

function mod:OnPlayerUpdate(player)
    local idx = player.ControllerIndex
    if
        Input.IsButtonPressed(Keyboard.KEY_W, idx)
        or Input.IsButtonPressed(Keyboard.KEY_A, idx)
        or Input.IsButtonPressed(Keyboard.KEY_S, idx)
        or Input.IsButtonPressed(Keyboard.KEY_D, idx)
        or Input.IsButtonPressed(Keyboard.KEY_SPACE, idx)
        or Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL, idx)
        or Input.IsButtonPressed(Keyboard.KEY_TAB, idx)
        or Input.IsButtonPressed(Keyboard.KEY_E, idx)
        or Input.IsButtonPressed(Keyboard.KEY_Q, idx)
    then
        keyboard_player = index(player)
    end
    if Input.IsButtonTriggered(Settings.key, idx) then
        local active_item = player:GetActiveItem(ActiveSlot.SLOT_POCKET)
        if active_item ~= 0 and not player:NeedsCharge(ActiveSlot.SLOT_POCKET) then
            player:UseActiveItem(active_item, 0, ActiveSlot.SLOT_POCKET)
            player:DischargeActiveItem(ActiveSlot.SLOT_POCKET)
        end
    end
    if reset_charge[index(player)] then
        local collectible = player:GetActiveItem(ActiveSlot.SLOT_POCKET)
        if collectible then
            player:SetActiveCharge(Isaac.GetItemConfig():GetCollectible(collectible).MaxCharges, ActiveSlot.SLOT_POCKET)
        end
        reset_charge[index(player)] = false
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPlayerUpdate)

local started = false
function mod:IntegrationSetup()
    if started then return end
    started = true
    if not ModConfigMenu then return end
    ModConfigMenu.RemoveCategory("Charged Keys")
    ModConfigMenu.AddSetting("Charged Keys", "Settings", {
        CurrentSetting = function ()
            return Settings.key
        end,
        Display = function ()
            return "Pocket Active Key: " .. InputHelper.KeyboardToString[Settings.key]
        end,
        Info = {"The new key for pocket active items"},
        OnChange = function (new_value)
            if type(new_value) ~= "number" then
                error("Pocket active key is not a number")
            end
            Settings.key = new_value
            SaveData()
        end,
        Type = ModConfigMenu.OptionType.KEYBIND_KEYBOARD,
        Popup = function ()
            return "The key is currently " .. InputHelper.KeyboardToString[Settings.key] .. ".\nTo change it, press a different key, or Esc to go back."
        end,
        PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL,
        PopupWidth = 280,
    })
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.IntegrationSetup)

local function SaveData()
    local data = { Settings = Settings }
    mod:SaveData(json.encode(data))
end

local function LoadData()
    if mod:HasData() then
        local data = json.decode(mod:LoadData())
        if data.Settings then
            Settings = data.Settings
        end
    end
end
LoadData()

function mod:OnNewLevel()
    SaveData()
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.OnNewLevel)

function mod:OnGameExit(save)
    SaveData()
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.OnGameExit)

function mod:OnGameEnd(irrelevant)
    LoadData()
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_END, mod.OnGameEnd)

function mod:OnStarted(irrelevant)
    LoadData()
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnStarted)
