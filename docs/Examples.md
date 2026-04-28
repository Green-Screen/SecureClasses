# WorkFlows
:::caution
When writing metamethods that interact with the main class be sure to use it's raw function to prevent C stack overflows such as `rawset`, `rawget`, `rawlen`, `rawequal`
:::
:::tip
`Userdata's` are almost identical to metatables but are limited as they are permanently read-only and should only be used for constant data that needs to be protected.
:::

### Wrapped Metatable

#### 1. Creating Transfer class
```lua
--!strict

-- Metatable test
local SecureClasses = require("../")

local T = {
	["Test1"] = true, -- Creates a default property Read-Only
	["_Protected"] = true, -- Creates a Protected property Internal only
	["__Metamethod"] = "Test", -- Creates a Metamethod property must be a legal metamethod AND must be written in the metamethod table (THIS WILL ERROR)
	["___UnProtected"] = "Test", -- Creates a Unprotected property without Read and Write restrictions
}

local MT = { -- Same syntax rules apply for MT as does T
	["Test2"] = false,
	UpdateTest1 = function(self: any, NewValue: any)
		rawset(self, "Test2", NewValue)
	end,
	["_Private"] = "Private",
	["___UnProtected2"] = "NewValue",
	["__Test"] = 12 -- Will cause error
}

type tabletype = { ["Test1"]: boolean } & { ["Test2"]: boolean }

local TransferTable = SecureClasses.NewMetatable(T, MT)
```

### 2. Assign metamethods
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

local Metamethods: SecureClasses.MetaMethods<tabletype> = { -- Must only contain legal metamethods
	__unm = function(s)
		s.Test1 = not s.Test1
		s.Test2 = not s.Test2
		return s
	end,

	__concat = function<V>(s, v: V)
		for i: any, k: any in v :: any do
			(s :: any)[i] = k
		end
		return s :: any
	end,

	__destroy = function(s)
		warn("Destroying class")
	end,

	__tostring = function() -- The ONLY writable metamethod that has a default
		return "Show this string when you print"
	end

}

local MetaTable = TransferTable:WriteMetamethods(Metamethods, "Protected Metatable")
```

### 3. Basic indexing and writing
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

-- Ok
print(MetaTable.Test1)
print(MetaTable.___UnProtected)

-- Not Ok
print(MetaTable._Protected1) -- Raise a warning returning nil
print(MetaTable.__Metamethod) -- This would throw an error before reaching this print

-- Will lock table and metatable with flag
-- table can be overwritten with __tostring metamethod
print(MetaTable, getmetatable(MetaTable))

-- Not Ok
MetaTable.Test1 = false -- Read only error
MetaTable._Protected1 = 200 -- Internal error
MetaTable.__Metamethod = function() end -- This would throw an error before reaching this write

-- Ok
MetaTable.___UnProtected = 1000::any
print(MetaTable.___UnProtected)


-- Metamethod to update default and private varible
MetaTable:UpdateTest1(20)

-- prints new value
print(MetaTable.Test2)
```

### 4. Destroy
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

-- Destroy with nuke
MetaTable:Destroy(true)

-- Not Ok
print(MetaTable.Test1)
print(MetaTable.Test2)

-- Empty
print(MetaTable, getmetatable(MetaTable))
```