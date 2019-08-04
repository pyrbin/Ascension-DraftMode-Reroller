---===[ GLobal variables ]===--- 
DRAFT_MAN_MACRO_CLICKED = false
DRAFT_MAN_WINDOW_HIDDEN = false
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

---===[ Local variables ]===--- 

local addonName = "draftman"
local macroName = "DraftMan - Spam Macro"
local draftDeckId = 777994

local isDraftReady = false
local isDraftRolling = false
local isDraftPreparing = false

local lastUpdate = 0
local openSetFrame = -1

local setFlags = { [1] = {}, [2] = {}, [3] = {}}

local cardCounter = 0
local cardPickDelay = 0.5
local cardSpellLookup = {
    [1] = nil,
    [2] = nil,
    [3] = nil
}

local hookedCardButtons = false

local learnCardIdx = nil
local tryLearnCard = false

local MAX_CARD_ROLLS = 4
local MAX_CARD_ROLLS_WITH_TAME_BEAST = 2


---===[ Frame events  ]===--- 

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

    if event == "ACTIONBAR_SLOT_CHANGED" and arg1 == DraftManFrame_RerollBar.action and not DRAFT_MAN_WINDOW_HIDDEN then
        DraftMan_CheckMacroValid()
    end

    if event == "ACTIONBAR_UPDATE_COOLDOWN" then
        DraftMan_StartRolling()
        DRAFT_MAN_MACRO_CLICKED = false
    end
end

function DraftMan_OnInit()
    -- Reroll bar state
    DraftManFrame_SpellSet:Hide();
    DraftManFrame_UnlockFrames:Hide()
    DraftManFrame_SetFrameVisibility(DRAFT_MAN_WINDOW_HIDDEN)
    DraftMan_CheckMacroValid()
end

function DraftMan_OnCardLearned()
    tryLearnCard = false
    for setIdx, flags in ipairs(setFlags) do
        if table.getn(flags) == 4 then
            DraftMan_log("|cFFE040FBWe found all picked spells for Set" .. setIdx)
            DraftMan_Exit()
            return
        end
    end
end

function DraftMan_OnUpdate()
    if not isDraftRolling then return end
    local hasChanged = false
    
    for i = 1, 3 do
        local id, name = getCardSpellInfo(i)
        if not hasChanged and id ~= cardSpellLookup[i] then
            hasChanged = true
        end
        cardSpellLookup[i] = id
    end

    if hasChanged and isDraftRolling then
        cardCounter = cardCounter + 1
        DraftMan_log("Card Reroll: " .. cardCounter)
        learnCardIdx = DraftMan_SelectCardToPick(cardSpellLookup)
        tryLearnCard = true
    end

    if tryLearnCard and learnCardIdx ~= nil then
        learnSpellCardAt(learnCardIdx)
    end

    if not DraftModeAccess:IsVisible() then
        DraftMan_log("Drafting done, did not find a set")
        DraftMan_StopRolling()
    end

end

---===[ Re-roll Logic  ]===--- 

function DraftMan_SetInActive()
    _G["DraftManFrame_RerollBar_Text"]:Show()
    isDraftReady = false
end

function DraftMan_SetActive()
    _G["DraftManFrame_RerollBar_Text"]:Hide()
    isDraftReady = true
end

function DraftMan_StartRolling()
    if not (deckIsOnCooldown() and isDraftReady 
    and not isDraftRolling and deckModeLoaded() 
    and macroExists() and not DRAFT_MAN_WINDOW_HIDDEN 
    and not isDraftPreparing and DRAFT_MAN_MACRO_CLICKED) then 
        return
    end

    isDraftPreparing = true
    DraftMan_LockInputFrames(true)

    if not hookedCardButtons then
        for i = 1,3 do
            _G["Card" .. tostring(i) .. "LearnSpellButton"]:HookScript("OnClick", DraftMan_OnCardLearned)
        end
        hookedCardButtons = true
    end

    for i = 1, 3 do
        for j = 1, 4 do
            local spells = DraftMan_ParseSpells(DRAFT_MAN_INPUTS[i][j])
            DRAFT_MAN_SETS[i][j] = spells
            if next(spells) == nil then
                table.insert(setFlags[i], j)
            end
        end
    end

    local count = 0

    for i = 1, 3 do
        if (table.getn(setFlags[i]) == 4) then
            count = count + 1
            setFlags[i] = {}
        end
    end

    if count == 4 then
        DraftMan_log("|cFF00FF00Canceled Roll, all sets empty!")
    end

    StaticPopup1Button1:Click()

    DraftMan_wait(.33, function()
        DraftMan_log("|cFF00FF00Start Rolling")
        isDraftRolling = true
        isDraftPreparing = false
    end)

end

function DraftMan_StopRolling()
    local tameBeastId = 965200
    
    if not (cardCounter == MAX_CARD_ROLLS or (cardCounter == MAX_CARD_ROLLS_WITH_TAME_BEAST and IsSpellKnown(tameBeastId))) then
        DraftMan_log("|cFFFF0000Missed rolls, stopped @ " .. cardCounter)
    end

    isDraftRolling = false

    DraftMan_wait(.25, function()
        setFlags = { [1] = {}, [2] = {}, [3] = {} }
        cardCounter = 0
        DraftMan_LockInputFrames(false)
        DraftMan_log("|cFFFF0000Stop Rolling")
    end)

end

function DraftMan_Exit() 
    DraftMan_StopRolling()
    DraftMan_DeleteMacroButton()
    Logout()
end

function DraftMan_SelectCardToPick(cards)
    local cardToPick = 1
    local setInfo = {}
    local minSpellsLeft = 99
    local minSpellIdx = -1

    -- Select card
    for setIdx, set in ipairs(DRAFT_MAN_SETS) do
        if (table.getn(setFlags[setIdx]) >= 0) then
            local found, spellsLeft, cardIdx, entryIdx = DraftMan_StepsToComplete(cards, setIdx)
            setInfo[setIdx] = { 
                ["found"] = found, ["spellsLeft"] = spellsLeft, 
                ["cardIdx"] = cardIdx, ["entryIdx"] = entryIdx
            }
            if spellsLeft < minSpellsLeft then
                minSpellsLeft = spellsLeft
                minSpellIdx = setIdx
            end
        end
    end

    local pickedInfo = setInfo[minSpellIdx]

    if pickedInfo.found then
        cardToPick = pickedInfo.cardIdx
        for setIdx, info in ipairs(setInfo) do
            if info.found and info.cardIdx == pickedInfo.cardIdx then
                table.insert(setFlags[setIdx], info.entryIdx)
                if setIdx == minSpellIdx then
                    DraftMan_log("|cFFE040FBFound spell for Set"..minSpellIdx.." | Entry: "..pickedInfo.entryIdx)
                    DraftMan_log("|cFFE040FBSpells left: "..DraftMan_SpellsLeft(minSpellIdx))
                    cardToPick = pickedInfo.cardIdx
                end
            end
        end
    end

    return cardToPick
end

function DraftMan_SpellsLeft(setIdx)
    return MAX_CARD_ROLLS - table.getn(setFlags[setIdx])
end

function DraftMan_StepsToComplete(cards, setIdx)
    local set = DRAFT_MAN_SETS[setIdx]
    local spellsLeft = DraftMan_SpellsLeft(setIdx)
    for cardIdx, cardSpell in ipairs(cards) do
        for entryIdx, entry in ipairs(set) do
            if not hasValue(setFlags[setIdx], entryIdx) then
                for _, spell in ipairs(entry) do
                    if cardSpell == spell then 
                        spellsLeft = spellsLeft - 1
                        return true, spellsLeft, cardIdx, entryIdx
                    end
                end
            end
        end
    end
    return false, spellsLeft, nil, nil
end

function DraftMan_ParseSpells(input)
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

---===[ Frame handling  ]===--- 

function DraftMan_CheckMacroValid()
    if deckIsEquiped() then
        DraftMan_SetActive()
        DraftManFrame_PickupDeckButton:Disable()
    else 
        DraftMan_SetInActive()
        DraftManFrame_PickupDeckButton:Enable()
    end
end

function DraftManFrame_SetFrameVisibility(status)
    if status then DraftManFrame:Show()
    else DraftManFrame:Hide() end
    DRAFT_MAN_WINDOW_HIDDEN = not status
    DraftMan_CheckMacroValid()
end

function DraftMan_CreateMacroButton()
    DraftMan_DeleteMacroButton()
    DRAFT_MAN_MACRO_ID = CreateMacro(macroName, 10, "#show\n/script _G['DRAFT_MAN_MACRO_CLICKED'] = true\n/click DraftManFrame_RerollBar", nil)
    DraftMan_log("Macro created! Please put it on action bar 1.")
    PickupMacro(macroName)
end

function DraftMan_DeleteMacroButton()
    DeleteMacro(macroName);
end

function DraftMan_LockInputFrames(lockFlag)
    -- Action bar lock
    if lockFlag then DraftManFrame_RerollBar:Disable()
    else DraftManFrame_RerollBar:Enable() end
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
end

function DraftManFrame_OnInputEdit(input, editbox)
    DRAFT_MAN_INPUTS[openSetFrame][input] = editbox:GetText()
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

function DraftMan_PickupDeck()
    PickupItem(draftDeckId) 
end

---===[ Slash command ]===--- 

local function DraftMan_HandleSlashCommand(msg)
    if msg == "show" then
        DraftManFrame_SetFrameVisibility(true)
    elseif msg == "hide" then
        DraftManFrame_SetFrameVisibility(false)
    end
end

SlashCmdList["DRAFTMAN"] = DraftMan_HandleSlashCommand
SLASH_DRAFTMAN1 = "/" .. addonName

---===[ Utilities ]===--- 

-- Prints message in chatbox
function DraftMan_log(msg)
	ChatFrame1:AddMessage("|cFFFFC107[DraftMan]: |r" .. tostring(msg))
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

function macroExists()
    local name = GetMacroInfo(macroName)
    return name ~= nil or name ~= ""
end

-- If deck (macro) is equiped at actionbar 1
function deckIsEquiped()
    local _, i = GetActionInfo(DraftManFrame_RerollBar.action)
    return i == draftDeckId;
end

-- If deck is on cooldown eg. has recently been used
function deckIsOnCooldown()
    local _, d, _ = GetItemCooldown(draftDeckId)
    return d > 0;
end

-- Empty tables
function emptyTable(t)
    count = #t
    for i=0, count do t[i]=nil end
end

-- Print table
function printTable(t)
    for _, e in ipairs(t) do print(e) end
end

function deckModeLoaded()
    return DraftModeAccess ~= nil
end

function hasValue (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
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