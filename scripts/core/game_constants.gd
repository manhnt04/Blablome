class_name GameConstants
extends RefCounted

## Game Constants & Enums for Blablome

enum Suit {
	FIRE,       # Hỏa (🔥)
	LIGHTNING,  # Lôi (⚡)
	WIND,       # Phong (🍃)
	DARK        # Ám (🌑)
}

enum Rarity {
	COMMON,     # Xám (#A0A0A0)
	UNCOMMON,   # Xanh dương (#4DA6FF)
	RARE,       # Vàng kim (#FFD700)
	LEGENDARY   # Hồng rainbow (#FF4D9D)
}

enum HandType {
	HIGH_CARD,
	PAIR,
	TWO_PAIR,
	THREE_OF_A_KIND,
	STRAIGHT,
	FLUSH,
	FULL_HOUSE,
	FOUR_OF_A_KIND,
	STRAIGHT_FLUSH
}

# 1-Second Readability Palettes (Impeccable standards)
const COLOR_BG := Color("#0a0a0f")
const COLOR_SURFACE := Color("#1a1a24")
const COLOR_SURFACE_LIGHT := Color("#2a2a3a")
const COLOR_SURFACE_BORDER := Color("#3a3a4e")

const COLOR_FIRE := Color("#ff4d4d")
const COLOR_LIGHTNING := Color("#ffd93d")
const COLOR_WIND := Color("#4dd97a")
const COLOR_DARK := Color("#9d4edd")

const COLOR_COMMON := Color("#a0a0a0")
const COLOR_UNCOMMON := Color("#4da6ff")
const COLOR_RARE := Color("#ffd700")
const COLOR_LEGENDARY := Color("#ff4d9d")

const COLOR_CHIPS := Color("#4da6ff")
const COLOR_MULT := Color("#ff4d4d")
const COLOR_MONEY := Color("#ffd700")

const SUIT_NAMES := {
	Suit.FIRE: "Hỏa",
	Suit.LIGHTNING: "Lôi",
	Suit.WIND: "Phong",
	Suit.DARK: "Ám"
}

const SUIT_ICONS := {
	Suit.FIRE: "🔥",
	Suit.LIGHTNING: "⚡",
	Suit.WIND: "🍃",
	Suit.DARK: "🌑"
}

const SUIT_COLORS := {
	Suit.FIRE: COLOR_FIRE,
	Suit.LIGHTNING: COLOR_LIGHTNING,
	Suit.WIND: COLOR_WIND,
	Suit.DARK: COLOR_DARK
}

const RARITY_COLORS := {
	Rarity.COMMON: COLOR_COMMON,
	Rarity.UNCOMMON: COLOR_UNCOMMON,
	Rarity.RARE: COLOR_RARE,
	Rarity.LEGENDARY: COLOR_LEGENDARY
}

const HAND_DATA := {
	HandType.HIGH_CARD: {"name": "Lá Cao", "chips": 5, "mult": 1},
	HandType.PAIR: {"name": "Một Đôi", "chips": 10, "mult": 2},
	HandType.TWO_PAIR: {"name": "Hai Đôi", "chips": 20, "mult": 2},
	HandType.THREE_OF_A_KIND: {"name": "Sám Cô", "chips": 30, "mult": 3},
	HandType.STRAIGHT: {"name": "Sảnh", "chips": 30, "mult": 4},
	HandType.FLUSH: {"name": "Đồng Chất", "chips": 35, "mult": 4},
	HandType.FULL_HOUSE: {"name": "Cù Lũ", "chips": 40, "mult": 4},
	HandType.FOUR_OF_A_KIND: {"name": "Tứ Quý", "chips": 60, "mult": 7},
	HandType.STRAIGHT_FLUSH: {"name": "Thùng Phá Sảnh", "chips": 100, "mult": 8}
}

const RANK_LABELS := {
	2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8", 9: "9", 10: "10",
	11: "J", 12: "Q", 13: "K", 14: "A"
}
