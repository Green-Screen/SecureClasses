# WorkFlows
:::caution
When writing metamethods that interact with the main class be sure to follow the class [writing style](#example):
:::

# Wrapped Metatable

:::info Sorting
You are able to mix around the data inside of the `Tabe`, `Metatable`, and `Metamethods` as during runtime they are sorted into their correct categories. __This is NOT recommended__. The reason is the returned `Wrapped Metatable` class type is the union of `T & MT` or `Table & Metatable` + `wrapped class` this allows the metamethods to not be included inside of the typed object. _Note: Due to the current state of type functions Private variables will be apart of the intellisense but **CANNOT** be accessed during runtime through normal indexing_.
:::

## 1. Creating a Header table
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

-- Properties. This should be the equivilent to the table of the class.
local Player = {
	Username = "Admin", -- Read only,
	_UserID = 12345678, -- Protected/Private
	__typeKey = "PlayerWrapper", -- Metamethod, This is legal but NOT RECOMMENDED
	___DisplayName = "Owner Of Game", -- Unprotected/Public
}
```
:::tip Property Denotions
**[Poperty Denotions](/api/SecuredMetatable)**
:::


## 2. Creating a Metadata table
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

--[[
	Syntax: self[__typeKey][PropertyToIndex]

	Tips:
	Cast self to any: (self :: any)
	This will clear any type errors due to the Property of __typeKey not being apart of the type union

	__typeKey cannot be indexed:
	Due to security your __typeKey cannot be indexed via: self[self.__typeKey]
	You must have a constant assigned to __typeKey and the index used to access the Metatable 
	object that holds the only reference to the private read-Only data {Protected, and Default objects}

	DO NOT INVOKE RAW FUNCTIONS:
	Due to the structure raw functions shouldn't be invoked.
]]
local PersonFunctions = {
["SetUsername"] = function(self: Player, newUsername: string)
	(self :: any).PlayerWrapper["Username"] = newUsername;
end,

["GetUserID"] = function(self: Player) : number
	return (self :: any).PlayerWrapper["_UserID"]
end,

["SetUserID"] = function(self, ID: number)
	(self :: any).PlayerWrapper["_UserID"] = ID
end,

}
```

:::tip Private and Default property indexing with meta-functions
To index a Private property or Default property **[Poperty Denotions](/api/SecuredMetatable)** through a meta-function you must index through the constant metamethod `__typeKey` _By default it is assigned to `Flag`_ but can be overwritten in the Metamethod table.
:::
### Example
```lua
-- Correct

local Player = {
	_UserID = 12345 -- Private Property
}
local PlayerMetadata = {
	["GetUserID"] = function(self)
		-- Cast self to any to suppress type error
		-- Index is = __typeKey
		return (self :: any).PlayerPrivateKey["_UserID"] -- Return: 12345
	end
}

local PlayerMetamethods = {
	__typeKey = "PlayerPrivateKey"
}

-- Incorrect

local Player = {
	_UserID = 12345 -- Private Property
}
local PlayerMetadata = {
	["GetUserID"] = function(self)
		-- Cast self to any to suppress type error
		-- Index is = __typeKey
		return (self :: any).__typeKey["_UserID"] -- Return: Attempt to index nil with "_UserID"
		-- When you index self it should be the literal of __typeKey
	end
}

local PlayerMetamethods = {
	__typeKey = "PlayerPrivateKey"
}
```
:::danger Raw functions
	Using raw functions inside of metadata functions and metamethods will lead to unexpected results.
:::

## 3. Creating a Metamethod table
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

local PlayerMetamethods:SecureClasses.metamethods<typeof(Player) & typeof(PlayerMetadata)> = {
	__typeKey = "PlayerWrapper", -- The index to access the metadata table

	__destroy = function(self, OptionalBooleanValue:boolean?) -- Function to run before auto destroy function
		print(self, "is being destroyed")
	end,

	__tostring = function(self:Person) -- metamethod that runs when you try to call toString() or print()
        return `Username: {self.Username}, UserID: {self.PlayerWrapper._UserID}`
    end,
}
```

:::caution Metamethod Statuses
Some metamethods are auto assigned and cannot be overwritten or read when creating the metamethod object. Check **[Metamethod Statuses](/api/SecuredMetatable#MetaMethods)** for information about every available metamethod supported by this class.
:::

## 4. Creating a Wrapped Metatable
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly
local SecureClasses = require("Path to SecureClasses Module")

local SecuredClass = SecureClasses(Player, PlayerMetadata, "Player", Playermetamethods)

print(SecuredClass) -- Returns __tostring Compile

print(getmetatable(SecuredClass)) -- "Player": = to Flag param

print(SecuredClass._UserID) -- Nil & Warn is raised

print(SecuredClass.Username) -- Admin

-- Assigns a new value to a public property
SecuredClass.___DisplayName = "Player1"

print(SecuredClass.___DisplayName) -- Player1

-- The metatable is never directly indexed so all metamethods remain protected
print(self.__typeKey) -- Nil
```
:::info Read-Only
By default there are 2 write protections that protect against writes even from raw functions
:::

## 5. Destroying a Wrapped Metatable
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly
local SecureClasses = require("Path to SecureClasses Module")

local SecuredClass = SecureClasses(Player, PlayerMetadata, "Player", Playermetamethods)

-- Error
SecuredClass.__index = nil -- table is read only

-- Runs __destroy first then AutoClean
SecuredClass:Destroy() -- prints (self, "is being destroyed")

print(SecuredClass, getmetatable(SecuredClass)) -- {}, nil

-- SecuredClass is now destroyed and deallocated
```

:::tip __destroy
Assign the metamethod `__destroy` to have a custom destroy function. Check limitations of `:Destroy()` **[Here](/api/SecuredMetatable#Destroy)**
:::