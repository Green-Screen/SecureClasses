--!strict

-- Documentation: https://green-screen.github.io/SecureClasses

local SecureClasses = require("../")
local EasyType = require("../Dependencies/EasyType")
local PersonData = {
	Age = 40, -- Default
	IsMale = true, -- Default
	_ID = "78", -- Private

	___TestInt = 30, -- Public
}

local PersonFunctions = {
	["SetAge"] = function(self: Person, NewAge: number)
		(self :: any).Person["Age"] = NewAge
		--(self :: any).Person["Age2"] = NewAge
	end,
	["SwapGender"] = function(self: Person)
		(self :: any).Person["IsMale"] = not (self :: any).Person["IsMale"]
	end,
	["SetID"] = function(self, ID: string)
		self.Person._ID = ID
	end,
	["GetID"] = function(self: Person): string
		return (self :: any).Person._ID
	end,
}

type Person = typeof(PersonData) & typeof(PersonFunctions)

local PersonMetaMethods: SecureClasses.MetaMethods<Person> = {
	__destroy = function(self: Person, Nuke: boolean?)
		warn("Destroying person")
	end,

	__tostring = function(self: Person)
		return `Age: {self.Age}, IsMale: {self.IsMale}`
	end,

	__add = function(self: Person, Value: number)
		local NewAge = self.Age + Value
		rawset((self :: any).__Metadata, "Age", NewAge)

		return NewAge
	end,

	__typeKey = "Person",
}

local Class = SecureClasses(PersonData :: Person, PersonFunctions :: Person, "Test", PersonMetaMethods)


print(Class, getmetatable(Class)) -- Tostring Result, Test

print(Class.Age) -- 40
print(Class._ID) -- Nil & Warn

Class:SetAge(500) -- Age = 500
print(Class:GetID()) -- "78"

print(Class.Age) -- 500

Class:SetID("300")

print(Class._ID) -- Nil & Warn
print(Class:GetID()) -- "300"

-- Error
--Class.Age = 30

Class:SwapGender() -- Not Gender

print(Class.IsMale) -- false

Class.___TestInt = 400 -- 400
print(Class.___TestInt) -- 400

print(Class, getmetatable(Class)) -- Tostring Result, Test

print(EasyType(Class)) -- table

Class:Destroy() -- nil

print(Class, getmetatable(Class)) -- {}, Nil

-- Error
Class:GetID() -- Attempt to index nil with GetID
