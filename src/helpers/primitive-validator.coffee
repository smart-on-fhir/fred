validators =
	integer: [/^-?\d+$/, "Please enter an integer"]
	unsignedInt: [/^[0-9]+$/, "Please enter a non-negative integer (e.g. >= 0)"]
	positiveInt: [/^[1-9][0-9]*$/, "Please enter a positive integer (e.g. > 0)"]
	id: [/^[A-Za-z0-9\-\.]{1,64}$/, "Please enter a combination of upper or lower case ASCII letters ('A'..'Z', and 'a'..'z', numerals ('0'..'9'), '-' and '.', with a length limit of 64 characters."]
	oid: [/^urn:oid:[0-2](\.[1-9]\d*)+$/, "Please enter an object id (OID) represented as a URI (RFC 3001); e.g. urn:oid:1.2.3.4.5"] 
	decimal: [/^-?\d+\.?\d+/, "Please enter a decimal"]
	instant: [/^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/, "Please enter a date/time value in ISO 8601 format (e.g. 1997-07-16T19:20:30+01:00)"]
	date: [/^-?[0-9]{4}(-(0[1-9]|1[0-2])(-(0[0-9]|[1-2][0-9]|3[0-1]))?)?$/, "Please enter a partial or full date in ISO 8601 format (e.g. 1997-07-16)"]
	dateTime: [/^-?[0-9]{4}(-(0[1-9]|1[0-2])(-(0[0-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?(Z|(\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00))?)?)?)?$/, "Please enter a partial date, full date or date and time in ISO 8601 format (e.g. 1997-07-16T19:20:30+01:00)"]
	time: [/^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?/, "Please enter a time value like 03:25:00"] 
	string: [/[^\s]/, "Please enter at least one character"]
	boolean: [/true|false/]

validatePopulated = (value) ->
	if value in [null, undefined, ""]
		"Please enter a value"
	else if /^\s+|\s+$/.test value
		"Value can't begin or end with spaces"
	else
		return null

validateFormat = (fhirType, value) ->
	validator = validators[fhirType] || validators["string"]
	return validator[1] unless validator[0].test value

module.exports.isValid = (fhirType, value, failBlank) ->
	if badFormat = validateFormat(fhirType, value)
		badFormat
	else if failBlank
		validatePopulated(value)