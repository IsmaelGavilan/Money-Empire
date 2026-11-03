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
