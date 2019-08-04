# DraftMan - WoW Ascension S4 Draft Mode Reroller

**DISCLAIMER: this addon was very roughly and quickly put together over 2\* nights so there might be bugs!**

- Auto-roller for Project Ascension Season 4 Draft Mode
- Designed with a key spammer in mind (its spammable)
- Simple GUI for selecting spells/sets
- Rolling as fast as possible (approx every 2-2.5s)

## Installation

- Go to releases and download source code
- Open the zip file and open the folder Ascension-DraftMode-Reroller-v.X
- Drag the folder DraftMan into your WoW-Ascension addons folder

## Guide

- Drag your "Draft Mode Deck" onto the Action Bar on the addon window (you can click the button "deck" to automatically pick it up)
- Click the "macro" button and put the macro on your prefered action bar
- Open a set (click button "SET1" etc..) and fill the fields with the Spell ids you want (list below)
- If you want to target more than one spell in a field you can seperate them by commas eg. "172, 688"
- Start spamming the Macro (or use your prefered key spammer)
- When a set is found the addon will delete the macro and logout

NOTE: Do not spam the deck item, only spam the macro!!!

![](use-example.gif "example use")

### An example of a set:

![](example.png "example set")

In this case the addon will keep rolling till Corruption (172) + either Summon Imp (688) or Shadow Bolt (686) is aquired

## Commands

- `/draftman show` - Show DraftMan window
- `/draftman hide` - Hide DraftMan window

## What Set is chosen?

At each roll of a draft the Set closest to completion is selected and a card/spell is picked based on the spells specified in the set.
If different sets are equally close the order will be based on lowest number eg. Set1 > Set2 > Set3.
Therefore having multiple sets with varying numbers of spells is not advised as the shorter ones will generally be picked.

## Troubleshooting

If you have problems try the following:

- /reload to reload the UI
- try spamming the macro a bit

If you find a bug or have suggestions please open an issue or contact me on Discord @ frans#8211

## Spell ids

NOTE: list taken from [another reroll addon](https://github.com/Malow/MaloWAscensionReroller#statistics-from-randomly-picking-spells)(much more advanced and feature rich than this one)

- Corruption - 172
- Charge - 100
- Seal of Righteousness - 21084
- Healing Wave - 331
- Bloodrage - 2687
- Searing Totem - 3599
- Mark of the Wild - 1126
- Overpower - 7384
- Righteous Fury - 25780
- Raptor Strike - 2973
- Sinister Strike - 1752
- Lightning Shield - 324
- Power Word: Fortitude - 1243
- Concussive Shot - 5116
- Swipe (Bear) - 779
- Fireball - 133
- Arcane Intellect - 1459
- Backstab - 53
- Blessing of Wisdom - 19742
- Defensive Stance - 71
- Thunder Clap - 6343
- Curse of Weakness - 702
- Devotion Aura - 465
- Life Tap - 1454
- Wrath - 5176
- Rejuvenation - 774
- Thorns - 467
- Summon Imp - 688
- Aspect of the Hawk - 13165
- Stoneskin Totem - 8071
- Fade - 586
- Demoralizing Roar - 99
- Demon Skin - 687
- Shield Bash - 72
- Maul - 6807
- Evasion - 5277
- Divine Protection - 498
- Smite - 585
- Heroic Strike - 78
- Victory Rush - 34428
- Healing Touch - 5185
- Earth Shock - 8042
- Sprint - 2983
- Shield Block - 2565
- Stoneclaw Totem - 5730
- Renew - 139
- Auto Shot - 965202
- Frostbolt - 116
- Battle Shout - 6673
- Arcane Shot - 3044
- Growl - 6795
- Shadow Word: Pain - 589
- Immolate - 348
- Serpent Sting - 1978
- Hunter's Mark - 1130
- Battle Stance - 2457
- Rend - 772
- Lightning Bolt - 403
- Hamstring - 1715
- Pick Pocket - 921
- Frost Armor - 168
- Blessing of Might - 19740
- Gouge - 1776
- Arcane Missiles - 5143
- Moonfire - 8921
- Shadow Bolt - 686
- Holy Light - 635
- Tame Beast - 965200
- Aspect of the Monkey - 13163
- Stealth - 1784
- Fire Blast - 2136
- Bear Form - 5487
- Mongoose Bite - 1495
- Curse of Agony - 980
- Eviscerate - 2098
- Taunt - 355
- Judgement of Light - 20271
- Judgement of Wisdom - 20354
