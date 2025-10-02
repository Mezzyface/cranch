# Quest Design Document: A Gem of a Problem (v2.0)

## Quest Line Overview

* **Quest Line Title:** A Gem of a Problem
* **Quest Giver:** Tim
* **Summary:** This quest line follows the escalating needs of **Tim**, a gem collector. The player will fulfill a series of orders by providing creatures that meet specific stat and tag-based criteria. This quest line serves as an extended tutorial, teaching the player to analyze a client's needs and select the appropriate creature from their collection, rather than simply following a set recipe.
* **Core Gameplay Loop:**
    1.  Receive a request from Tim with a list of required stats and tags.
    2.  Analyze the player's own collection of creatures to find a suitable match.
    3.  (If no match exists) Breed, tame, or train a creature to meet the criteria.
    4.  Deliver the qualifying creature(s) to Tim.
    5.  Receive rewards and unlock the next stage of the quest line.

---

## Quest 1: Study Guard

* **Quest ID:** `TIM-01`
* **Prerequisites:** Completion of the game's initial tutorial.
* **Dialogue Snippet:** "My gems! They're disappearing! I need a guard for my study—something small, but vigilant, that will stay put and watch over my collection!"
* **Objectives:**
    * Provide Tim with one creature that meets the following criteria:
        * **Tag:** `[Small]`
        * **Tag:** `[Territorial]`
        * **Minimum Stat:** `Discipline (DIS) > 80`
        * **Minimum Stat:** `Wisdom (WIS) > 70`
* **Success Conditions:** Tim accepts a creature that meets all four conditions.
* **Rewards:** 300 Gold 💰, 50 XP.
* **Designer Notes:** This introductory quest teaches the core mechanic of matching tags and stats. An early-game creature like a Scuttleguard or Quill-Cat would easily meet these requirements, giving the player a straightforward first step.

---

## Quest 2: Going Underground

* **Quest ID:** `TIM-02`
* **Prerequisites:** Quest `TIM-01` completed.
* **Dialogue Snippet:** "It's been disabled! I'm moving my collection to a cave for safety. I need something truly tough for the entrance—durable, strong, and able to see in the pitch black."
* **Objectives:**
    * Provide Tim with one creature for his cave entrance that meets the following criteria:
        * **Tag:** `[Dark Vision]`
        * **Minimum Stat:** `Constitution (CON) > 120`
        * **Minimum Stat:** `Strength (STR) > 110`
* **Success Conditions:** Tim accepts a creature that meets all three conditions.
* **Rewards:** 400 Gold 💰, 150 XP, unlocks **Tim's Cave** as a delivery location.
* **Designer Notes:** This quest introduces environmental tags (`[Dark Vision]`) and higher stat requirements. A player might use a stone-type creature, a heavily armored insectoid, or a subterranean mammal, depending on their specialty.

---

## Quest 3: Cave Ecology 101

* **Quest ID:** `TIM-03`
* **Prerequisites:** Quest `TIM-02` completed.
* **Dialogue Snippet:** "The guard is perfect, but the *inside* is a mess! It's damp, there are bugs everywhere, and little crawlers are leaving slime on my gems. I need a full clean-up crew!"
* **Objectives:**
    * **Part 1 (Sanitation):** Provide **one** creature with the `[Bioluminescent]` tag and the `[Cleanser]` tag (consumes fungus/waste).
    * **Part 2 (Pest Control):** Provide at least **one** creature with the `[Flies]` tag and a `Dexterity (DEX) > 100`.
    * **Part 3 (Internal Patrol):** Provide at least **two** creatures with the `[Stealthy]` tag and a `Wisdom (WIS) > 100`.
* **Success Conditions:** Tim accepts creatures that fulfill the criteria for all three parts.
* **Rewards:** 1500 Gold 💰, 300 XP.
* **Designer Notes:** This is a major skill-check for the player. They must solve three separate problems, encouraging a diverse stable of creatures. It moves beyond simple "guard" duty into specialized utility roles.

---

## Quest 4: Subterranean Shipping

* **Quest ID:** `TIM-04`
* **Prerequisites:** Quest `TIM-03` completed.
* **Dialogue Snippet:** "My collection is growing, and moving materials through these tunnels is back-breaking work. I need a couple of helpers—strong, smart enough to sort things, and disciplined enough to follow my directions."
* **Objectives:**
    * Provide Tim with **two** creatures for logistics. Each creature must meet the following criteria:
        * **Tag:** `[Sure-Footed]`
        * **Minimum Stat:** `Strength (STR) > 130`
        * **Minimum Stat:** `Intelligence (INT) > 90`
        * **Minimum Stat:** `Discipline (DIS) > 110`
* **Success Conditions:** Tim accepts two creatures that meet all the requirements.
* **Rewards:** 1800 Gold 💰, 250 XP.
* **Designer Notes:** This quest focuses on a combination of physical and mental stats for a utility role, showcasing the importance of well-rounded creatures.

---

## Quest 5: The Living Lock

* **Quest ID:** `TIM-05`
* **Prerequisites:** Quest `TIM-04` completed.
* **Dialogue Snippet:** "I've built a vault for my most precious pieces. I need a guardian that *is* the vault door. Something that can sit perfectly still, blend in with the rocks, and endure anything."
* **Objectives:**
    * Provide Tim with one "living lock" creature that meets the following criteria:
        * **Tag:** `[Camouflage]`
        * **Minimum Stat:** `Constitution (CON) > 200`
        * **Minimum Stat:** `Discipline (DIS) > 180`
* **Success Conditions:** Tim accepts a creature that meets all three high-level requirements.
* **Rewards:** 2500 Gold 💰, 500 XP, Item: **1x Flawless Sapphire** (rare breeding component).
* **Designer Notes:** This is a high-tier, specialized request. The stat requirements are steep, likely forcing the player to train a creature specifically for this role or use one of their rare "champion" creatures.

---

## Quest 6: Dungeon Master's Decree

* **Quest ID:** `TIM-06`
* **Prerequisites:** Quest `TIM-05` completed.
* **Dialogue Snippet:** "It's time to expand! I need builders for a new wing, more guards for another entrance, and... something to challenge worthy visitors. A creature of great intellect!"
* **Objectives:**
    * **Part 1 (Guards):** Provide **three** creatures that meet the criteria from Quest 2 (`CON > 120`, `STR > 110`, `[Dark Vision]`).
    * **Part 2 (Construction):** Provide **one** creature with the `[Constructor]` tag and `Strength (STR) > 250`.
    * **Part 3 (Puzzle-Master):** Provide **one** creature with the `[Sentient]` tag and `Intelligence (INT) > 230`.
* **Success Conditions:** Tim accepts creatures that fulfill the criteria for all three parts. A cutscene plays showing the dungeon coming to life.
* **Rewards:** 7500 Gold 💰, 1200 XP, Shop Upgrade: **"Tim's Geological Marvel,"** "Preferred Contractor" Status (unlocks radiant quests).
* **Designer Notes:** The capstone quest requires the player to demonstrate mastery over several disciplines: breeding for combat, utility, and high-intelligence roles. The rewards are significant and provide a gateway to endgame content.