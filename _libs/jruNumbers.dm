/*
	JRutils - Numbers
	by Lummox JR
	version 1.0

	Utility procs for working with numbers in text


	Vars exposed by this library:

	jru_plurals

		This is an associative list containing pluralizations that have already
		been made, This also can be used to add words that don't use standard
		plurals, like "deer":

		jru_plurals["deer"] = "deer"

		Adding values to this list should be done at runtime, e.g. in a proc
		called by world/New().


	Procs exposed by this library:

	jru_Pluralize(word, n=0)

		Returns the plural of word, based on the value of n; if n=1 then the
		word is unchanged. Otherwise the word is pluralized according to
		standard English rules. The capitalization of the word is left intact.
		This is a fancier version of the \s macro.

		Exceptions to the rules should be noted by adding them to jru_plurals
		at runtime. See above.

	jru_PlurlizeText(txt)

		Looks for all instaces of "[number] [word]" in a piece of text, and
		wherever this pattern is found, the word is pluralized if need be based
		on the number. For instance, jru_PluralizeText("4 point") will return
		"4 points". The changed text is returned.

	jru_Commafy(n)

		Returns the number n with commas. n may be in number or text form.

	jru_CommafyText(txt)

		Returns the original text, but with commas inserted into any numbers as
		needed.

	jru_NumberText(n, th)

		Returns the number n converted into a written form, so 1 becomes "one".
		If the th argument is true, this is a -th form, so 1 becomes "first".

		n may be in number or text form.

	jru_NumbersText(txt)

		Looks for any numbers in the original text, and replaces them with
		written forms. If the number is followed by st, nd, rd, or th, it
		becomes a -th form.

		Example:
		jru_NumbersText("This is the 3rd time I ever got over 100 points.")

		Result:
		"This is the third time I ever got over one hundred points."

	jru_Leading(n, places="1", fill="0")

		Prints out the number in text form with leading zeroes to fit the
		space needed. For instance, jru_Leading(seconds,2) will produce the
		seconds portion of a time counter.


	Other useful procs:

	jru_SplitText(txt, delimit="/")

		Splits up a string where each item is separated by a delimiter, and
		returns a list.

	jru_SanitizeNum(n, no_negative=0, no_decimal=0)

		Takes a number in num or text form and converts it to sanitized text.
		An example is converting 1e6 to "1000000". You can specify if negative
		or decimal values are allowed.

		This can be used to remove commas from numbers as well, so if you use
		commas in "prettified" scores, you can remove them easily again.
		Remember the result is text, so you have to use text2num() to convert
		this back to a number.
 */



/*
	Lists meant to be added to at runtime
 */

var/list/jru_plurals = new

/*
	Helper procs
 */

// Helper proc to split text into lists so compiled-in string count is kept low
// Can't use params2list() for this purpose because the result may not include repeated entries
proc/jru_SplitText(txt, delimit)
	. = list()
	if(!txt) return
	if(!delimit) delimit = ascii2text(47)
	var/i
	i = findtextEx(txt, delimit)
	while(i)
		. += copytext(txt, 1, i++)
		txt = copytext(txt, i)
		i = findtextEx(txt, delimit)
	. += txt

/*
	Caps styles:

	0: No caps
	1: All caps
	2: Leading caps
	3: Leading caps, including after hyphens
 */
proc/jru_CapsType(word)
	if(!word || !istext(word)) return 0
	var/ch = text2ascii(word,1)
	if(ch >= 97 && ch < 122) return 0
	if(length(word) == 1) return 2
	ch = text2ascii(word,1)
	if(ch >= 65 && ch < 90) return 1
	var/i = findtextEx(word,"-")
	if(i && i+1 < length(word))
		ch = text2ascii(word,i+1)
		if(ch >= 65 && ch < 90) return 3
	return 2

proc/jru_Capify(word, capstype=0)
	if(word && istext(word))
		switch(capstype)
			if(0) return lowertext(word)
			if(1) return uppertext(word)
			if(2) return uppertext(copytext(word,1,2)) + lowertext(copytext(word,2))
			if(3)
				var/i = findtextEx(word,"-")
				if(i++) return jru_Capify(copytext(word,1,i), 1) + jru_Capify(copytext(word,i), capstype)
				return uppertext(copytext(word,1,2)) + lowertext(copytext(word,2))
	return word

// Helper proc to find a number in a bigger piece of text
proc/jru_FindNumber(txt, idx=1, th_ok)
	var/len=length(txt), i, j, ch
	for(, idx<=len, ++idx)
		ch = text2ascii(txt, idx)
		if(ch < 48 || ch > 57) continue
		// number found
		var/decimal = 0
		i = idx++
		for(j=idx, j<=len, ++j)
			ch = text2ascii(txt, j)
			if(ch == 46 && !decimal)
				decimal = 1
				continue
			if(ch == 44 && !decimal)
				continue
			if(ch < 48 || ch > 57) break
		idx = j + 1
		// trailing decimal or comma is puncutation after the number
		while(j > i)
			ch = text2ascii(txt, j-1)
			if(ch < 48 || ch > 57) --j
			else break
		if(j <= i) continue
		// number can only be followed by letters if th_ok is true
		if(!th_ok && j<=len)
			ch = text2ascii(txt, j)
			if((ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122)) continue
		// number must be preceded by a non-letter or start of text
		if(i > 1)
			ch = text2ascii(txt, i-1)
			if(ch == 45)	// leading negative is OK
				--i
				if(i > 1) ch = text2ascii(txt, i-1)
				else ch = 32
			// is this not a number?
			if((ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122)) continue
		return list(i,j)
	return

// Internal proc to convert text-format number into something readable, or actual number into string form
proc/jru_SanitizeNum(n=0, no_negative, no_decimal)
	if(isnum(n))
		if(no_negative && n < 0) n = -n
		if(no_decimal) n = round(n, 1)
		n = num2text(n, 999)
	if(!istext(n)) n = "0"
	// strip commas
	var/idx = findtextEx(n, ascii2text(44))
	while(idx)
		n = copytext(n, 1, idx) + copytext(n, idx+1)
		idx = findtextEx(n, ascii2text(44))
	// strip negative
	if(no_negative)
		if(n && text2ascii(n,1) == 45) n = copytext(n, 2)
	// look for scientific notation
	idx = findtext(n, ascii2text(69))
	if(idx)
		var/e = round(text2num(copytext(n, idx+1) || 0))
		n = text2num(copytext(n, 1, idx) || 0)
		while(e > 0)
			n *= 10
			--e
		while(e < 0)
			n /= 10
			++e
		if(no_negative && n < 0) n = -n
		if(no_decimal) n = round(n, 1)
		n = num2text(n, 999)
	// strip any non-digits
	for(idx=1, idx<=length(n), ++idx)
		var/ch = text2ascii(n,idx)
		if(ch < 48 || ch > 57)
			if(ch == 45 && !no_negative && idx == 1)
				continue
			if(ch == 46 && !no_decimal)
				no_decimal = 1
				continue
			n = copytext(n, 1, idx)
			break
	return n

/*
	Main library procs
 */

/*
	Pluralize a word based on standard English rules and the number given. If
	the number is 1, the word is left intact. Words that are exceptions to these
	rules should be added to jru_plurals, which is an associative list, at
	runtime. An example might be:

	jru_plurals["deer"] = "deer"

	The rules are as follows:

	- If a word ends in ch, sh, zz, s, or x, the plural ends in -es.
	- If a word ends in z but not zz, the z is doubled and -es is added.
	- If a word ends in y but the y is not preceded by a vowel, the y is
	  replaced with -ies.
	- All other words are pluralized with -s.

	Example plurals:

	hat => hats
	witch => witches
	marsh => marshes
	pass => passes
	box => boxes
	buzz => buzzes
	quiz => quizzes
	enemy => enemies
	key => keys

	Capitalization format of the original word is left intact.
 */
proc/jru_Pluralize(word, n=0)
	if(!n) n = 0
	if(!isnum(n)) n = text2num(n)
	if(n == 1) return word	// singular
	if(!word || !istext(word)) return word
	var/caps = jru_CapsType(word)
	word = lowertext(word)
	. = jru_plurals[word]
	if(.) return jru_Capify(., caps)
	var/lastch = text2ascii(word, length(word))
	var/lastch2 = length(word)>1 ? text2ascii(word, length(word)-1) : 0
	var/add = ascii2text(115)
	if(lastch == 104)
		// ch or sh
		if(lastch2 == 99 || lastch2 == 115)
			add = ascii2text(101) + add
	// s, x
	else if(lastch == 115 || lastch == 120)
		add = ascii2text(101) + add
	// z or zz
	if(lastch == 122)
		add = ascii2text(101) + add
		if(lastch2 && lastch2 != 122) add = ascii2text(122) + add
	// y, but not not vowel+y
	else if(lastch == 121 && lastch2 && !(lastch2 in list(97,101,105,111,117)))
		word = copytext(word, 1, length(word))
		add = ascii2text(105) + ascii2text(101) + add
	. = word + add
	jru_plurals[word] = .
	return jru_Capify(., caps)

// Pluralize a whole section of text
var/list/jru_inword
proc/jru_PluralizeText(txt)
	if(!jru_inword) jru_inword = list(ascii2text(45), ascii2text(39))
	var/idx, len=length(txt), i, j, n, word, ch
	while(idx <= len)
		j = jru_FindNumber(txt, idx)
		if(!j) break
		i = j[1]
		j = j[2]
		idx = j+1
		// number must have a space and a word after to be useful here
		if(j > len || text2ascii(txt,j) > 32) continue

		n = text2num(jru_SanitizeNum(copytext(txt, i, j)))

		// skip spaces
		while(idx <= len)
			ch = text2ascii(txt, idx)
			if(ch <= 32)
				++idx
				continue
			break
		if(idx > len) continue

		// look for a word here
		ch = text2ascii(txt, idx)
		if(!(ch >= 65 && ch <= 90) && !(ch >= 97 && ch <= 122) && !(ch in jru_inword))
			++idx
			continue
		i = idx++
		for(j=idx, j<=len, ++j)
			ch = text2ascii(txt, j)
			if(!(ch >= 65 && ch <= 90) && !(ch >= 97 && ch <= 122) && !(ch in jru_inword)) break
		idx = j + 1
		// a number is not part of a word, and doesn't count as post-word punctuation; move on
		if(j<=len && ch >= 48 && ch <= 57) continue
		// remove in-word punctuation at the end of the word; make sure there still is a word!
		while(j > i && (text2ascii(txt,j-1) in jru_inword)) --j
		if(j <= i) continue
		// now pluralize the number + word combo
		word = jru_Pluralize(copytext(txt, i, j), n)
		txt = copytext(txt,1,i) + word + copytext(txt,j)
		j = length(word) - (j-i)
		idx += j
		len += j
	return txt

proc/jru_Commafy(n=0)
	. = jru_SanitizeNum(n)
	if(!.) return
	var/begin = 1
	if(text2ascii(.,1) == 45) ++begin
	var/end = findtextEx(., ascii2text(46)) || (length(.)+1)
	while(end-begin > 3)
		end -= 3
		. = copytext(., 1, end) + ascii2text(44) + copytext(., end)

proc/jru_CommafyText(txt)
	var/idx=1, len=length(txt), i, j, comma
	while(idx <= len)
		j = jru_FindNumber(txt, idx)
		if(!j) break
		i = j[1]
		j = j[2]
		idx = j
		if(j-i <= 3) continue
		comma = jru_Commafy(copytext(txt,i,j))
		if(length(comma) > j-i)
			txt = copytext(txt,1,i) + comma + copytext(txt,j)
			j = length(comma) - (j-i)
			idx += j
			len += j
	return txt

/*
	Convert a number to written form.

	This proc only handles whole positive numbers. The number can be in text
	form.

	If the th argument is nonzero, the text result will be in ordinal form such
	as "tenth" instead of "ten".
 */
var/list/jru_numtext
proc/jru_NumberText(n=0, th)
	if(!jru_numtext)
		var/list/L = jru_SplitText("zero/one/two/three/four/five/six/seven/eight/nine/ten/eleven/twelve/thirteen/fourteen/fifteen/sixteen/seventeen/eighteen/nineteen/twenty/thirty/forty/fifty/sixty/seventy/eighty/ninety/hundred/thousand/million/billion/trillion/t/th/y/ieth/ve/fth/one/first/two/second/three/third/e/th")
		jru_numtext = new(6)
		jru_numtext[1] = L[1]			// zero
		jru_numtext[2] = L.Copy(2,21)	// one - nineteen
		jru_numtext[3] = L.Copy(21,29)	// twenty - ninety
		jru_numtext[4] = L[29]			// hundred
		jru_numtext[5] = L.Copy(30,34)	// thousand, million, billion, trillion
		jru_numtext[6] = L.Copy(34,48)	// replacement endings for -th
	var/idx

	n = jru_SanitizeNum(n,1,1)
	if(!n || n == "0")
		. = jru_numtext[1]
		if(th) . += jru_numtext[6][4]
		return

	. = ""
	var/size = 0		// what is this group's place? 0=units, 1=thousands, etc.
	var/firstgroup = 0	// was there a units group?
	while(n)
		// chop off the last 3 digits from n
		idx = max(1, length(n)-2)
		var/mil = text2num(copytext(n,idx))
		n = copytext(n,1,idx)

		// roman numerals to clarify what each digit is for
		var/c = round(mil / 100)
		var/x = round((mil / 10) % 10)
		var/i = mil % 10

		var/g = ""	// g is the text for this 3-digit group

		// "[c] hundred"
		if(c) g = jru_numtext[2][c] + " " + jru_numtext[4]

		if(i || x)
			if(c) g += " "	// space after hundred
			if(x < 2)
				// 1-19 already exist in ready text form
				g += jru_numtext[2][x*10+i]
			else
				// 20-90
				g += jru_numtext[3][x-1]
				if(i)
					// add hyphen and last digit
					g += ascii2text(45)
					g += jru_numtext[2][i]
		/*
			If this group has text, apply a place label like "thousand" if it
			needs one. Go up through trillions, and then print as "thousand
			trillion" or whatever because including labels past the trillions is
			silly.
		 */
		if(g && size)
			var/s = size
			if(s%4)
				g += " " + jru_numtext[5][(s+3)%4+1]
				s -= s%4
			while(s >= 4)
				g += " " + jru_numtext[5][4]
				s -= 4
		// If this group has any text, add it to the total
		if(g)
			if(.) g += ascii2text(44) + " "
			. = g + .
			if(!size) firstgroup = 1
		++size	// move up to next group

	/*
		Look for extraneous commas. This happens in numbers like "one thousand
		twenty-four", which up to this point would be "one thousand, twenty-four"
		which is stilted.

		Rules:

		- The units group must be present
		- There must be only one other group with text (that is, only one comma)
		- The units group must not contain "hundred"
	 */
	idx = findtextEx(., ascii2text(44))
	if(firstgroup && idx && !findtextEx(., ascii2text(44), idx+1) && !findtextEx(., jru_numtext[4], idx+2))
		. = copytext(., 1, idx) + copytext(., idx+1)

	/*
		Ordinal -th format has been requested, so apply the following
		conversions:

		1) At the end of the number in text form:
			-t becomes -th (as in eight => eighth)
			-y becomes -ieth (as in twenty => twentieth)
			-ve becomes -fth (as in five => fifth)
			one becomes first
			two becomes second
			three becomes third
			-e becomes -th (as in nine => ninth)
			Any other case has -th added

		2) If there is a leading "one" with just one other word, strip it out,
		   so "one hundredth" becomes "hundredth", as in, "That was Bob's
		   hundredth win." The former is acceptable but more stilted and
		   unlikely to be called for.
	 */
	if(th)
		var/list/L = jru_numtext[6]
		var/len1 = length(.)
		// look for endings to replace
		for(idx=1, idx<L.len, idx+=2)
			var/len2 = length(L[idx])
			if(len1 >= len2 && copytext(., len1-len2+1) == L[idx])
				. = copytext(., 1, len1-len2+1) + L[idx+1]
				len1 = length(.)
				break
		if(idx >= L.len)
			. += L[L.len]
			len1 += 2
		// look for leading "one" with only one other word like "hundred" or "million" after
		if(len1 > 4 && text2ascii(.,4) == 32 && !findtextEx(., " ", 5) && findtext(., jru_numtext[2][1]) == 1)
			. = copytext(., 5)

var/list/jru_numtext2
proc/jru_NumbersText(txt)
	if(!jru_numtext2)
		jru_numtext2 = jru_SplitText("st/nd/rd/th")

	var/idx=1, len=length(txt), i, j, k, n, th, ending, len2
	while(idx <= len)
		j = jru_FindNumber(txt, idx, 1)
		if(!j) break
		i = j[1]
		j = j[2]
		idx = j

		th = 0
		n = jru_SanitizeNum(copytext(txt,i,j),1,1)
		world << copytext(txt,i,j)

		// look for st, nd, rd, th
		for(k=1, k<=jru_numtext2.len, ++k)
			ending = jru_numtext2[k]
			len2 = length(ending)
			if(j+len2 <= len+1 && findtext(txt,ending,j,j+len2) == j)
				j += len2
				idx = j
				th = 1
				break
		if(!th && j<=len)	// if one of those wasn't found, letters trailing number mean don't textify
			var/ch = text2ascii(txt, j)
			if((ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122)) continue

		n = jru_NumberText(n, th)
		txt = copytext(txt,1,i) + n + copytext(txt,j)
		j = length(n) - (j-i)
		idx += j
		len += j
	return txt

proc/jru_Leading(n, places=1, fill="0")
	. = jru_SanitizeNum(n,1,1)
	var/neg
	if(. && text2ascii(.) == 45)
		neg = 1
		. = copytext(., 2)
		--places
	while(length(.) < places)
		. = fill + .
	if(neg) . = ascii2text(45) + .
