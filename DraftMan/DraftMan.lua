-- Global
DRAFT_MAN_MACRO_ID = -1
DRAFT_MAN_SETS = {
    [1] = { [1] = nil, [2] = nil, [3] = nil, [4] = nil },
    [2] = { [1] = nil, [2] = nil, [3] = nil, [4] = nil },
    [3] = { [1] = nil, [2] = nil, [3] = nil, [4] = nil }
}
DRAFT_MAN_INPUTS = {
    [1] = { [1] = "", [2] = "", [3] = "", [4] = "" },
    [2] = { [1] = "", [2] = "", [3] = "", [4] = "" },
    [3] = { [1] = "", [2] = "", [3] = "", [4] = "" }
}

-- Local 
local macroName = "DraftManReroll - DO NOT TOUCH";

local isDraftReady = false
local isDraftRolling = false

local lastUpdate = 0
local pickedSpells = {}

local openSetFrame = -1
local lastButton = nil

local prioritySet = nil
local prioritySetFlags = {}

-- Prints message in chatbox
function DraftMan_log(msg)
	ChatFrame1:AddMessage("[DraftMan]: " .. tostring(msg))
end

-- Gets spell card info
function getCardSpellInfo(index)
    local spells = {
        [1] = Card1.SpellFrame.Icon.Spell,
        [2] = Card2.SpellFrame.Icon.Spell,
        [3] = Card3.SpellFrame.Icon.Spell
    }
    local name = GetSpellInfo(spells[index])
	return spells[index], name
end

-- Learn spell card at position
function learnSpellCardAt(index)
    _G["Card" .. tostring(index) .. "LearnSpellButton"]:Click()
end

-- If deck (macro) is equiped at actionbar 1
function deckIsEquiped()
    local _, i, _ = GetActionInfo(DraftManFrame_RerollBar.action)
    return i == DRAFT_MAN_MACRO_ID;
end

-- If deck is on cooldown eg. has recently been used
function deckIsOnCooldown()
    local draftDeckId = 777994
    local _, d, _ = GetItemCooldown(draftDeckId)
    return d > 0;
end

-- Empty tables
function emptyTable(t)
    count = #t
    for i=0, count do t[i]=nil end
end

function printTable(t)
    count = #t 
    for i=0, count do print(t[i]) end
end

-- Frame functions
function DraftMan_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    this:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    DraftMan_log("Loaded v1")
end

function DraftMan_OnEvent(event)
    if event == "VARIABLES_LOADED" then
        DraftMan_OnInit()
    end
    
    if event == "ACTIONBAR_SLOT_CHANGED" and arg1 == DraftManFrame_RerollBar.action then
        DraftMan_CheckMacroValid()
    end

    if event == "ACTIONBAR_UPDATE_COOLDOWN" then
        if deckIsOnCooldown() and isDraftReady and not isDraftRolling then
            DraftMan_StartRolling()
        end
    end
end

function DraftMan_CheckMacroValid()
    if deckIsEquiped() then
        DraftMan_SetActive()
        DraftManFrame_CreateMacroButton:Disable()
    else 
        DraftMan_SetInActive()
        DraftManFrame_CreateMacroButton:Enable()
    end
end

function DraftMan_OnInit()
    -- Reroll bar state
    DraftManFrame_SpellSet:Hide();
    DraftManFrame_UnlockFrames:Hide()
    DraftMan_CheckMacroValid()
end

function DraftMan_LockInputFrames(lockFlag)
    -- Buttons lock
    if lockFlag then
        DraftManFrame_SetButtons1:Disable()
        DraftManFrame_SetButtons2:Disable()
        DraftManFrame_SetButtons3:Disable()
        DraftMan_OpenSetFrame(openSetFrame, nil)
        for i = 1, 3 do
            _G["DraftManFrame_SpellSet_Input"..i]:ClearFocus()
        end
        DraftManFrame_UnlockFrames:Show()
    else
        DraftManFrame_SetButtons1:Enable()
        DraftManFrame_SetButtons2:Enable()
        DraftManFrame_SetButtons3:Enable()
        DraftManFrame_UnlockFrames:Hide()
    end
    DraftMan_CheckMacroValid()
    -- Action bar lock
    DraftManFrame_RerollBar:EnableKeyboard(not lockFlag)
    DraftManFrame_RerollBar:EnableMouse(not lockFlag)
end

function DraftMan_StartRolling()
    isDraftRolling = false
    DraftMan_LockInputFrames(true)
    StaticPopup1Button1:Click()

    for i = 1, 3 do
        for j = 1, 4 do
            local spells = DraftManFrame_ParseSets(DRAFT_MAN_INPUTS[i][j])
            DRAFT_MAN_SETS[i][j] = spells
        end
    end

    DraftMan_wait(.25, function()
        isDraftRolling = true
    end)

end

function DraftMan_StopRolling()
    prioritySet = nil
    emptyTable(prioritySetFlags)
    isDraftRolling = false
    DraftMan_LockInputFrames(false)
end

function DraftMan_FoundSet() 
    DraftMan_StopRolling()
    DraftMan_DeleteMacroButton()
    Logout()
end

function DraftManFrame_OnInputEdit(input, editbox)
    DRAFT_MAN_INPUTS[openSetFrame][input] = editbox:GetText()
end

function DraftManFrame_ParseSets(input)
    local spells = {}
    for spell in string.gmatch(input, '([^,]+)') do
        -- Trim string
        spell = spell:gsub("^%s*(.-)%s*$", "%1")
        -- Remove non numerics
        spell = spell:gsub("[^0-9]", "")
        -- To number
        spell = tonumber(spell)
        table.insert(spells, spell)
    end
    return spells
end

function DraftMan_OpenSetFrame(set, button)
    -- Unhighlight all buttons
    for i = 1,3 do
        _G["DraftManFrame_SetButtons"..i]:UnlockHighlight()
    end

    -- Close spell set frame if double-click
    if openSetFrame == set then
        openSetFrame = -1
        DraftManFrame_SpellSet:Hide()
        return
    end

    -- Open spell set frame
    openSetFrame = set
    button:LockHighlight()
    DraftManFrame_SpellSet:Show()
    for i = 1, 4 do
        _G["DraftManFrame_SpellSet_Input"..i]:SetText(DRAFT_MAN_INPUTS[set][i])
    end
end

-- todo: does not work FIX
function DraftMan_OnUpdate(elapsed)
    if not isDraftRolling then return end

    if lastUpdate + 0.45 > GetTime() then return end
    lastUpdate = GetTime()

    -- Check if is done
    if prioritySet ~= nil then
        local done = true
        for idx, spells in ipairs(DRAFT_MAN_SETS[prioritySet]) do
            if not DraftMan_FoundSetEntry(idx, spells) then
                done = false
                break
            end
        end
        if done then
            DraftMan_log("We found all picked spells :)")
            DraftMan_FoundSet()
            return
        end
    end

    -- Check if Draft mode is enabled
    if DraftModeAccess == nil or not DraftModeAccess:IsVisible() then
        DraftMan_log("Draft cards not visible :(")
        DraftMan_StopRolling()
        return
    end

    -- Check if a picked spell is shown
    local found = false

    -- This monstrosity of a loop :o
    for i = 1, 3 do
        local id, name = getCardSpellInfo(i)
        -- We have found a set
        if prioritySet ~= nil then
            for idx, spells in ipairs(DRAFT_MAN_SETS[prioritySet]) do
                if not DraftMan_FoundSetEntry(idx, spells) then
                    found = DraftMan_MatchAndLearnSpell(spells, id, i)
                    if found then
                        table.insert(prioritySetFlags, idx)
                        return
                    end
                end
            end
        else -- Search for a matching set
            for idx, set in ipairs(DRAFT_MAN_SETS) do
                for _, spells in ipairs(set) do 
                    found = DraftMan_MatchAndLearnSpell(spells, id, i)
                    if found then
                        prioritySet = idx
                        return
                    end
                end
            end
        end
    end

    -- No picked spell are shown, pick leftmost
    DraftMan_log("Picking leftmost spell")
    learnSpellCardAt(1)

end

function DraftMan_FoundSetEntry(idx, spells)
    if next(spells) == nil then return true end
    if prioritySetFlags[idx] ~= nil then return true end
    --for _, spell in ipairs(spells) do
    --    if IsSpellKnown(spell) then return true end
    --end
    return false
end

function DraftMan_MatchAndLearnSpell(spells, id, cardIdx)
    for _, spellId in ipairs(spells) do
        if id == spellId then
            DraftMan_log("Picked spell found @ card"..cardIdx)
            learnSpellCardAt(cardIdx)
            return true
        end
    end
    return false
end

function DraftMan_CreateMacroButton()
    DraftMan_DeleteMacroButton()
    DRAFT_MAN_MACRO_ID = CreateMacro(macroName, 10, "#show\n/use Draft Mode Deck", nil)
    DraftMan_log("Macro created! Please put it on action bar 1.")
    PickupMacro(macroName)
end

function DraftMan_DeleteMacroButton()
    DeleteMacro(macroName);
end

function DraftMan_SetInActive()
    _G["DraftManFrame_RerollBar_Text"]:Show()
    isDraftReady = false
end

function DraftMan_SetActive()
    _G["DraftManFrame_RerollBar_Text"]:Hide()
    isDraftReady = true
end

-- Wait func 
local waitTable = {};
local waitFrame = nil;

function DraftMan_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end