--!strict
local SecureClasses = require("../")
local PersonData = {
	Age = 40,
	IsMale = true,
	_ID = "78",

	___TestInt = 30,
}

local PersonFunctions = {
	["SetAge"] = function(self: Person, NewAge: number)
		(self :: any).Person["Age"] = NewAge;
        (self :: any).Person["Age2"] = NewAge
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

type PersonData = {
	Age: number,
	IsMale: boolean,
	_ID: string,
	___TestInt: number,
}

type PersonMethods = {
	SetAge: (self: Person, NewAge: number) -> (),
	SwapGender: (self: Person) -> (),
	SetID: (self: Person, ID: string) -> (),
	GetID: (self: Person) -> string,
}

type Person = PersonData & PersonMethods

local PersonMetaMethods: SecureClasses.MetaMethods<Person> = {
	__destroy = function(self: Person, Nuke: boolean?)
		warn("Destroying person")
	end,

	__tostring = function(self:Person)
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

print(Class, getmetatable(Class))

print(Class.Age)
print(Class._ID)

Class:SetAge(500)
print(Class:GetID())

print(Class.Age)

-- Error
--print(Class._ID)

-- Error
--Class.Age = 30

Class:SwapGender()

print(Class.IsMale)

Class.___TestInt = 400
print(Class.___TestInt)

print(Class, getmetatable(Class))

Class:Destroy()

print(Class, getmetatable(Class))
