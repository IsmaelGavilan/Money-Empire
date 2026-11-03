class_name BigMoney
extends RefCounted
## Nonnegative integer, exact decimal arithmetic. Public operations return new values.
## Null means invalid input, underflow or overflow; no float conversion is accepted.
const MAX_DIGITS: int = 300
const MAX_SMALL: int = 1000000
var _digits: String = "0"

static func parse(text: String) -> BigMoney:
	if text.is_empty() or text.length() > MAX_DIGITS:
		return null
	for index in text.length():
		if text.unicode_at(index) < 48 or text.unicode_at(index) > 57:
			return null
	var value := BigMoney.new()
	var first := 0
	while first < text.length() - 1 and text[first] == "0":
		first += 1
	value._digits = text.substr(first)
	return value

func decimal() -> String:
	return _digits

func compare(other: BigMoney) -> int:
	if _digits.length() != other._digits.length():
		return 1 if _digits.length() > other._digits.length() else -1
	if _digits == other._digits:
		return 0
	return 1 if _digits > other._digits else -1

func add(other: BigMoney) -> BigMoney:
	if other == null:
		return null
	var left := _digits.length() - 1
	var right := other._digits.length() - 1
	var carry := 0
	var output := ""
	while left >= 0 or right >= 0 or carry > 0:
		var total := carry
		if left >= 0:
			total += _digits.unicode_at(left) - 48
		if right >= 0:
			total += other._digits.unicode_at(right) - 48
		output = str(total % 10) + output
		carry = total / 10
		left -= 1
		right -= 1
	return parse(output)

func subtract(other: BigMoney) -> BigMoney:
	if other == null or compare(other) < 0:
		return null
	var output := ""
	var right := other._digits.length() - 1
	var borrow := 0
	for left in range(_digits.length() - 1, -1, -1):
		var digit := _digits.unicode_at(left) - 48 - borrow
		if right >= 0:
			digit -= other._digits.unicode_at(right) - 48
		borrow = 1 if digit < 0 else 0
		if digit < 0:
			digit += 10
		output = str(digit) + output
		right -= 1
	return parse(output)

func multiply_small(factor: int) -> BigMoney:
	if factor < 0 or factor > MAX_SMALL:
		return null
	# Temporary result may have extra digits; parse rejects overflow atomically.
	var output := ""
	var carry := 0
	for index in range(_digits.length() - 1, -1, -1):
		var total := (_digits.unicode_at(index) - 48) * factor + carry
		output = str(total % 10) + output
		carry = total / 10
	while carry > 0:
		output = str(carry % 10) + output
		carry = carry / 10
	return parse(output)

func divide_small_ceil(divisor: int) -> BigMoney:
	return _divide_small(divisor, true)

func divide_small_floor(divisor: int) -> BigMoney:
	return _divide_small(divisor, false)

func _divide_small(divisor: int, round_up: bool) -> BigMoney:
	if divisor <= 0 or divisor > MAX_SMALL:
		return null
	var output := ""
	var remainder := 0
	for index in _digits.length():
		var total := remainder * 10 + _digits.unicode_at(index) - 48
		output += str(total / divisor)
		remainder = total % divisor
	var result := parse(output)
	return result.add(parse("1")) if round_up and remainder > 0 else result
