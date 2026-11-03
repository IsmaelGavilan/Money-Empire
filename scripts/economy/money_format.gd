class_name MoneyFormat
extends RefCounted
## Abbreviations truncate to two decimals, never change the underlying integer.
## Spanish long scale and English short scale are intentionally distinct.
static func abbreviated(value: BigMoney, locale: String = "es") -> String:
	if value == null:
		return "—"
	var digits := value.decimal()
	var exponent := digits.length() - 1
	if exponent < 3:
		return digits
	var spanish := locale.begins_with("es")
	var group: int = exponent / 3
	if group > 6:
		var fraction := digits.substr(1, 2).rstrip("0")
		return digits[0] + (("," if spanish else ".") + fraction if not fraction.is_empty() else "") + "e" + str(exponent)
	var suffixes: Array = ["", " mil", " M", " mil M", " B", " mil B", " T"] if spanish else ["", "K", "M", "B", "T", "Qa", "Qi"]
	var whole_digits := digits.length() - group * 3
	var fraction := digits.substr(whole_digits, 2).rstrip("0")
	return digits.substr(0, whole_digits) + (("," if spanish else ".") + fraction if not fraction.is_empty() else "") + suffixes[group]

static func rate(milli_per_second: BigMoney, locale: String = "es") -> String:
	if milli_per_second == null:
		return "— /s"
	var digits := milli_per_second.decimal()
	if digits.length() >= 7:
		return abbreviated(milli_per_second.divide_small_floor(1000), locale) + " /s"
	digits = digits.pad_zeros(4)
	var fraction := digits.right(3).rstrip("0")
	return digits.left(digits.length() - 3) + (("," if locale.begins_with("es") else ".") + fraction if not fraction.is_empty() else "") + " /s"
