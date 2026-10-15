extends RefCounted
class_name CanglanVillageTrade
## Real world-ledger barter. Trade never invents money or stock.
## Can be called by a player's trade UI or an NPC planner.
## One engine tick: preflight both inventories, then transfer both legs.
const World = preload("res://scripts/world_state.gd")

static func barter(world: WorldState, seller: String, buyer: String,
		sell_kind: String, sell_units: int, pay_kind: String, pay_units: int) -> bool:
	if world == null or seller.is_empty() or buyer.is_empty() or seller == buyer:
		return false
	if not world.entities.has(seller) or not world.entities.has(buyer):
		return false
	if sell_kind.is_empty() or pay_kind.is_empty() or sell_kind == pay_kind:
		return false
	if sell_units <= 0 or pay_units <= 0:
		return false
	if world.quantity(seller, sell_kind) < sell_units:
		return false
	if world.quantity(buyer, pay_kind) < pay_units:
		return false
	# Each WorldState.transfer is authoritative and updates physical entity
	# ownership as well as inventory. Preflight makes a partial trade impossible
	# in the single-threaded WorldState tick.
	if not world.transfer(seller, buyer, sell_kind, sell_units):
		return false
	var paid: bool = world.transfer(buyer, seller, pay_kind, pay_units)
	if not paid:
		# Defensive rollback against future transfer implementation changes.
		assert(world.transfer(buyer, seller, sell_kind, sell_units))
		return false
	world.ledger.append({
		"tick": world.tick, "action": "barter",
		"seller": seller, "buyer": buyer,
		"goods": sell_kind, "goods_amount": sell_units,
		"payment": pay_kind, "payment_amount": pay_units
	})
	return true


static func best_survival_offer(world: WorldState, actor: String, partner: String) -> Dictionary:
	## Deterministic, zero-LLM utility decision: offer surplus firewood for
	## vegetables only if personal hunger stock is under 2 and seller has
	## at least 3 surplus firewood. No imaginary debt or forced trades.
	if world == null or not world.entities.has(actor) or not world.entities.has(partner):
		return {}
	if world.quantity(actor, "vegetables") >= 2:
		return {}
	if world.quantity(actor, "firewood") <= 3 or world.quantity(partner, "vegetables") < 2:
		return {}
	return {
		"seller": actor, "buyer": partner,
		"sell_kind": "firewood", "sell_units": 2,
		"pay_kind": "vegetables", "pay_units": 2
	}


static func execute_offer(world: WorldState, offer: Dictionary) -> bool:
	for key in ["seller", "buyer", "sell_kind", "sell_units", "pay_kind", "pay_units"]:
		if not offer.has(key):
			return false
	return barter(world,
		String(offer["seller"]), String(offer["buyer"]),
		String(offer["sell_kind"]), int(offer["sell_units"]),
		String(offer["pay_kind"]), int(offer["pay_units"]))
