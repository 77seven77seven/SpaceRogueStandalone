
// File:    autojoining.dm
// Library: Forum_account.Autojoining
// Author:  Forum_account
//
// Contents:
//   This library provides procs that compute state numbers for
//   different autojoining schemes. It defines the autojoin16,
//   autojoin47, and autojoin256 procs for turfs and movable atoms.

proc
	// the dir4 and dir8 procs aren't used for autojoining, but I do
	// often use them to initialize turfs with a random direction.
	dir4()
		return pick(NORTH, SOUTH, EAST, WEST)

	dir8()
		return pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)

// the turf procs take a variable name and a value that are
// used when checking each neighbor.
turf
	proc
		autojoin16(var_name, var_value = 1)

			var/n = 0
			var/turf/t

			t = locate(x, y + 1, z)
			if(t && t.vars[var_name] == var_value) n |= 1
			t = locate(x + 1, y, z)
			if(t && t.vars[var_name] == var_value) n |= 2
			t = locate(x, y - 1, z)
			if(t && t.vars[var_name] == var_value) n |= 4
			t = locate(x - 1, y, z)
			if(t && t.vars[var_name] == var_value) n |= 8

			return n

		autojoin47(var_name, var_value = 1)

			var/n = 0
			var/turf/t

			// check the sides.
			t = locate(x, y + 1, z)
			if(t && t.vars[var_name] == var_value) n |= 7
			t = locate(x + 1, y, z)
			if(t && t.vars[var_name] == var_value) n |= 28
			t = locate(x, y - 1, z)
			if(t && t.vars[var_name] == var_value) n |= 112
			t = locate(x - 1, y, z)
			if(t && t.vars[var_name] == var_value) n |= 193

			// check the corners if we need to.
			if(!(n & 1))
				t = locate(x - 1, y + 1, z)
				if(t && t.vars[var_name] == var_value) n |= 1

			if(!(n & 4))
				t = locate(x + 1, y + 1, z)
				if(t && t.vars[var_name] == var_value) n |= 4

			if(!(n & 16))
				t = locate(x + 1, y - 1, z)
				if(t && t.vars[var_name] == var_value) n |= 16

			if(!(n & 64))
				t = locate(x - 1, y - 1, z)
				if(t && t.vars[var_name] == var_value) n |= 64

			return n

		autojoin256(var_name, var_value = 1)

			var/n = 0
			var/turf/t

			t = locate(x - 1, y + 1, z)
			if(t && t.vars[var_name] == var_value) n |= 1
			t = locate(x    , y + 1, z)
			if(t && t.vars[var_name] == var_value) n |= 2
			t = locate(x + 1, y + 1, z)
			if(t && t.vars[var_name] == var_value) n |= 4
			t = locate(x + 1, y    , z)
			if(t && t.vars[var_name] == var_value) n |= 8
			t = locate(x + 1, y - 1, z)
			if(t && t.vars[var_name] == var_value) n |= 16
			t = locate(x    , y - 1, z)
			if(t && t.vars[var_name] == var_value) n |= 32
			t = locate(x - 1, y - 1, z)
			if(t && t.vars[var_name] == var_value) n |= 64
			t = locate(x - 1, y    , z)
			if(t && t.vars[var_name] == var_value) n |= 128

			return n

// the autojoin procs for movable atoms don't take any
// parameters, they just check to see if each neighboring
// tile also contains an object of the same type.
atom
	movable
		proc
			autojoin16()

				var/n = 0
				var/turf/t

				t = locate(x, y + 1, z)
				if(t && locate(type) in t) n |= 1
				t = locate(x + 1, y, z)
				if(t && locate(type) in t) n |= 2
				t = locate(x, y - 1, z)
				if(t && locate(type) in t) n |= 4
				t = locate(x - 1, y, z)
				if(t && locate(type) in t) n |= 8

				return n

			autojoin47(var_name, var_value = 1)

				var/n = 0
				var/turf/t

				// check the sides.
				t = locate(x, y + 1, z)
				if(t && locate(type) in t) n |= 7
				t = locate(x + 1, y, z)
				if(t && locate(type) in t) n |= 28
				t = locate(x, y - 1, z)
				if(t && locate(type) in t) n |= 112
				t = locate(x - 1, y, z)
				if(t && locate(type) in t) n |= 193

				// check the corners if we need to.
				if(!(n & 1))
					t = locate(x - 1, y + 1, z)
					if(t && locate(type) in t) n |= 1

				if(!(n & 4))
					t = locate(x + 1, y + 1, z)
					if(t && locate(type) in t) n |= 4

				if(!(n & 16))
					t = locate(x + 1, y - 1, z)
					if(t && locate(type) in t) n |= 16

				if(!(n & 64))
					t = locate(x - 1, y - 1, z)
					if(t && locate(type) in t) n |= 64

				return n

			autojoin256(var_name, var_value = 1)

				var/n = 0
				var/turf/t

				t = locate(x - 1, y + 1, z)
				if(t && locate(type) in t) n |= 1
				t = locate(x    , y + 1, z)
				if(t && locate(type) in t) n |= 2
				t = locate(x + 1, y + 1, z)
				if(t && locate(type) in t) n |= 4
				t = locate(x + 1, y    , z)
				if(t && locate(type) in t) n |= 8
				t = locate(x + 1, y - 1, z)
				if(t && locate(type) in t) n |= 16
				t = locate(x    , y - 1, z)
				if(t && locate(type) in t) n |= 32
				t = locate(x - 1, y - 1, z)
				if(t && locate(type) in t) n |= 64
				t = locate(x - 1, y    , z)
				if(t && locate(type) in t) n |= 128

				return n
