# 🃏 Chkobba (Scopa) Card Game Project: Comprehensive Presentation

## 🌟 Project Overview

This project is a digital implementation of Chkobba (also known as Scopa), a highly strategic and traditional Mediterranean fishing card game for two players. The primary goal is to capture face-up cards from a central playing area, earning points not just for the quantity of cards captured, but also for specific combinations and 'sweeps.'

We are using an expanded 48-card deck (A-K in 4 suits) for this digital version, which simplifies mapping to standard international playing cards and increases the strategic options compared to the traditional 40-card Italian deck.

## 🚀 Core Gameplay Mechanics

The game is played in multiple deals (rounds) until the entire deck is exhausted. Players are dealt three cards each round, and four cards are initially placed face-up on the table.

### The Two Ways to Capture Cards

A player captures cards by playing a card from their hand onto the table. There are two capture methods:

1. Matching by Rank (Preferred):

   - The played card must match the exact value of a single card on the table.

   - Example: Playing a King (Value 13) captures the King (Value 13) on the table.

2. Matching by Sum:

   - The played card's value must equal the sum of two or more cards on the table.

   - Example: Playing a 10 (Value 10) captures a 6 (Value 6) and a 4 (Value 4) from the table.

> Priority Rule (Crucial):
>
> If a player can capture cards using both the Matching by Rank method (single card) AND the Matching by Sum method (multiple cards), the player MUST choose the single card match. This rule adds a significant layer of forced strategy.

>Non-Capture Moves
>
>If a played card cannot make any valid capture, it is simply added to the central playing area, becoming available for future captures.

>Chkobba / Scopa (The Sweep)
>
>A Chkobba (or Scopa) is achieved when a player successfully captures all cards currently on the table with a single move. This immediately earns the player 1 point on the score tracker, and the captured cards are placed in their score pile.

## 🔢 Card Value System (48-Card Deck)

For capture and summing purposes, the 48-card deck uses a consistent numerical value sequence:

| Card Rank    | Chkobba Capture Value | Notes                            |
| ---------    | --------------------- | -----------------------          |
| Ace (A)      | 1                     | Lowest numerical value.          |
| 2 through 10 | 2 through 10          | Face value matches capture value.|
| Jack (J)     | 11                    | First face card.                 |
| Queen (Q)    | 12                    | Second face card.                |
| King (K)     | 13                    | Highest numerical value.         |

## 🏆 Scoring Highlights (Points at End of Game)

After the deck is played through and all remaining table cards are assigned to the last player to capture, the round ends. Points are then calculated based on the cards in each player's capture pile.

| Scoring Category     | Point Value | Description                                                                          |
| ----------------     | ----------- | -----------                                                                          |
| Most Cards           | 1 Point     | Awarded to the player who captured the majority of the 48 cards (25 or more).        |
| Most Diamonds        | 1 Point     | Awarded to the player who captured the majority of the 12 Diamond cards (7 or more). |
| The Seven of Diamonds| 1 Point     | Awarded to the player who captured the actual 7 of Diamonds.                         |
| Highest Primiera     | 1 Point     | Awarded to the player whose best four cards (one from each suit) yield the highest specific Primiera score. (The Primiera score is calculated using special high-value cards, e.g., 7s are worth 21, 6s are worth 18, Aces are worth 16, etc.) |
| Chkobba (Sweeps)     | 1 Point per sweep  | Awarded for every time a player cleared the table during the game. |

The total score for the game is the sum of all these category points plus the Chkobba points.

## 🛠️ Project Status

Current components implemented:

* Complete deck generation (48 cards) and value assignment (1-13).

* Robust shuffling algorithm.

* Initial dealing mechanism for the table and player hands.

* Basic UI structure and card rendering.

## Next Steps:

The immediate focus is to fully implement the capture logic within the handleCardPlay function, addressing both rank matching and sum matching, while strictly enforcing the Priority Rule.