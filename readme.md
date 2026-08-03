# 🃏 Chkobba (شكبّة) Card Game Project: Presentation

## 🌟 Project Overview

A digital implementation of **Chkobba** (Arabic: شكبّة / škkubba, sometimes written "Chkobba"), a traditional
Mediterranean *fishing* card game for two players famously played in Tunisia. The goal is to capture face-up
cards from a central playing area, earning points not just for the quantity of captured cards but also for
specific combinations and for *chkobba* (sweeps). Play continues over several *manches* until one player
reaches the target score (default **21**; 11 and 31 are also commonly used).

This version uses the **traditional 40-card deck** (4 suits × 10 cards), with the Tunisian ranks mapped onto
standard international card faces for rendering.

## 🚀 Core Gameplay Mechanics

A *manche* is played over 6 rounds (deals). Each round both players are dealt 3 cards; 4 cards are initially
placed face-up on the table. Play resumes after each round with the player whose turn it is.

### The Two Ways to Capture Cards

A player captures cards by playing a card from their hand onto the table. There are two capture methods:

1. **Capture by value (manger / أكل):**
   - The played card must match the exact value of a single card on the table.
   - Example: playing a **7** captures the **7** on the table.

2. **Capture by sum:**
   - The played card's value must equal the sum of two or more cards on the table.
   - Example: playing a **K (10)** captures a **6** and a **4**.

> **Priority rule (crucial):**
>
> If a played card can capture by direct *value match* (single card) **and** by sum, the player **must**
> choose the single-card match. This is enforced automatically by the game.

> **Non-capture moves:**
> A card that cannot capture is simply added to the table, becoming available for future captures.

> **Chkobba (the sweep):**
> Clearing **all** cards from the table with a single move earns a **chkobba** worth 1 point.
> A chkobba is **not** awarded on the very last move of a manche.

> **Initial re-deal:**
> If the 4 initial table cards contain 3 of the same value, the table is re-dealt so the game never
> starts with an un-capturable ("imprenable") configuration.

## 🔢 Card Value System (40-card Deck)

| Tunisian rank          | Rendered rank | Capture value |
| ---------------------- | ------------- | ------------- |
| L'as (l'āṣ), "1"       | A             | 1             |
| 2 – 7                  | 2 – 7         | face value    |
| Dame (مجيرة)           | Q             | 8             |
| Fante / Valet (كوال)   | J             | 9             |
| Roi (راي)               | K             | 10            |

Diamonds are called **Dīnārī (ديناري)**.

## 🏆 Scoring (manche end)

After the deck is exhausted, the remaining table cards are given to the **player who made the last capture**
(last pli winner). Points are then computed per category. On a tie in a category neither player scores
(**bājī** — the point is void).

| Category      | Arabic / Term    | Points | How it is won                          |
| ------------- | ---------------- | ------ | -------------------------------------- |
| **Most cards**| Kārta (كارطة)    | 1      | Captured the majority of the 40 cards. |
| **Most diamonds** | Dīnārī (ديناري) | 1      | Captured the most diamonds (of 10).    |
| **Barmīla**   | Barmīla (برميلة) | 1      | Most **7s**; tie → most **6s**; else bājī. |
| **Seven of diamonds** | Sabʿa l-ḥayya (سبعة الحية) | 1 | Owns the **7 of diamonds**. |
| **Chkobba**   | Chkobba (شكبّة)  | 1 each | Each sweep of the table during the manche. |

> Sabʿa l-ḥayya (سبعة الحية, "the living seven") — the **7 of diamonds** is the **only card** that scores by
> itself in classic Chkobba.

The winner is the first player to reach the target score (default 21). A value of 11 or 31 is also commonly
used.

## 🛠️ Project Status

Implemented:

- Traditional **40-card deck** generation with authentic values (1, 2–7, Q=8, J=9, K=10).
- Robust shuffling, initial table deal with three-of-a-kind re-deal rule.
- Capture logic: direct value match (forced priority) and subset checksum.
- **Chkobba (sweep)** detection, with the last-move exclusion rule.
- End-of-manche scoring: **Kārta, Dīnārī, Barmīla, Sabʿa l-ḥayya, chkobba**, with bājī ties.
- Multi-manche matches to a configurable target score.
- Single-player vs AI, and network **1vs1** (ENet) with host-authoritative scoring.