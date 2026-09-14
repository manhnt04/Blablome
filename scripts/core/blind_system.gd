class_name BlindSystem
extends RefCounted

# Ported directly from balatro-gba blind.c:
# static const u32 ANTE_LUT[] = {100, 300, 800, 2000, 5000, 11000, 20000, 35000, 50000};
const ANTE_LUT: Array[int] = [100, 300, 800, 2000, 5000, 11000, 20000, 35000, 50000]

enum BlindType {
	SMALL,
	BIG,
	BOSS
}

enum Stake {
	WHITE,
	RED,
	GREEN,
	BLACK,
	BLUE,
	PURPLE,
	ORANGE,
	GOLD
}

const BLIND_REWARDS: Dictionary = {
	BlindType.SMALL: 3,
	BlindType.BIG: 4,
	BlindType.BOSS: 5
}

const BLIND_MULTIPLIERS: Dictionary = {
	BlindType.SMALL: 1.0,
	BlindType.BIG: 1.5,
	BlindType.BOSS: 2.0
}

static func get_base_ante_score(ante: int) -> int:
	var clamped_ante: int = clampi(ante, 1, 8)
	return ANTE_LUT[clamped_ante]

static func get_blind_target_score(ante: int, blind_type: BlindType, boss_id: String = "", stake: int = 0) -> int:
	var base_score: int = get_base_ante_score(ante)
	var mult: float = BLIND_MULTIPLIERS.get(blind_type, 1.0)
	
	# Special boss multiplier overrides from Balatro
	if blind_type == BlindType.BOSS:
		if boss_id == "the_wall":
			mult = 4.0 # The Wall requires 4x base
		elif boss_id == "violet_vessel":
			mult = 6.0 # Violet Vessel requires 6x base
			
	var stake_mult: float = 1.0
	if stake >= Stake.PURPLE:
		stake_mult = 1.6
	elif stake >= Stake.GREEN:
		stake_mult = 1.3
		
	return int(round(base_score * mult * stake_mult))

static func get_blind_reward(blind_type: BlindType) -> int:
	return BLIND_REWARDS.get(blind_type, 3)

static func calculate_cashout(blind_type: BlindType, current_money: int, remaining_hands: int, remaining_discards: int = 0, is_green_deck: bool = false, interest_cap: int = 5, stake: int = 0) -> Dictionary:
	var base_reward: int = get_blind_reward(blind_type)
	if stake >= Stake.RED and blind_type == BlindType.SMALL:
		base_reward = 0 # Red Stake rule: Small Blind gives no reward
	var hand_bonus: int = 0
	var discard_bonus: int = 0
	var interest_bonus: int = 0
	
	if is_green_deck:
		# Green Deck rule: No interest, but +$2 per remaining hand and +$1 per remaining discard
		hand_bonus = remaining_hands * 2
		discard_bonus = remaining_discards * 1
		interest_bonus = 0
	else:
		# Standard Balatro rule: +$1 per remaining hand, +$1 per $5 up to interest cap
		hand_bonus = remaining_hands * 1
		var raw_interest: int = int(float(current_money) / 5.0)
		interest_bonus = mini(interest_cap, maxi(0, raw_interest))
		
	var total_cashout: int = base_reward + hand_bonus + discard_bonus + interest_bonus
	
	return {
		"base_reward": base_reward,
		"blind_reward": base_reward,
		"hand_bonus": hand_bonus,
		"hands_bonus": hand_bonus,
		"discard_bonus": discard_bonus,
		"interest_bonus": interest_bonus,
		"total_payout": total_cashout,
		"total_earned": total_cashout
	}
