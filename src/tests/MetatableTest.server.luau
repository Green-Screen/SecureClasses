--!strict

-- Metatable test
local SecureClasses = require("../")

local T = {
	["Test1"] = true,
}

local MT = {
	["Test2"] = false,
	UpdateTest1 = function(self: any, NewValue: any)
		rawset(self, "Test2", NewValue)
	end,
}

type tabletype = { ["Test1"]: boolean } & { ["Test2"]: boolean }

local TransferTable = SecureClasses.NewMetatable(T, MT)

local Metamethods: SecureClasses.MetaMethods<tabletype> = {
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
}

local MetaTable = TransferTable:WriteMetamethods(Metamethods, "Protected Metatable")

-- Ok
print(MetaTable.Test1)
print(MetaTable.Test2)

-- Not ok
print(MetaTable.Test3)

-- Will lock table and metatable with flag
-- table can be overwritten with __tostring metamethod
print(MetaTable, getmetatable(MetaTable))

-- Not ok will error
--MetaTable.Test2 = nil

-- Metamethod to update private varible
MetaTable:UpdateTest1(20)

-- prints new value
print(MetaTable.Test2)

MetaTable:Destroy(true)

-- Not Ok
print(MetaTable.Test1)
print(MetaTable.Test2)

-- Empty
print(MetaTable, getmetatable(MetaTable))
