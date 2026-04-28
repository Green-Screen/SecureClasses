-- SecureClasses V 1.4.1
-- @Patriots8800

--!strict

----------------------------------------------------------------------------------------------

-- 							[[ Dependencies ]]
local EasyType = require("./SecureClasses/Dependencies/EasyType")

----------------------------------------------------------------------------------------------

-- 							[[ Service Header ]]

-- Secure Classes is a Metatable and Userdata wrapper object ment to bring security and ease of use to all objects
local SERVICE_NAME = "[SecureClasses]:"

----------------------------------------------------------------------------------------------

-- 							[[ Private functions (helpers) ]]

local UnderscoreASCII = string.byte("_") -- = 95

local MetamethodStatuses = {
	["__index"] = false, -- Not writtable
	["__newindex"] = false, -- Not writtable
	["__call"] = true,
	["__concat"] = true,
	["__unm"] = true,
	["__iter"] = true,
	["__add"] = true,
	["__sub"] = true,
	["__mul"] = true,
	["__div"] = true,
	["__idiv"] = true,
	["__mod"] = true,
	["__pow"] = true,
	["__tostring"] = true,
	["__len"] = true,
	["__eq"] = true,
	["__lt"] = true,
	["__le"] = true,
	["__mode"] = true,
	["__metatable"] = false, -- Not writtable
	["__destroy"] = true, -- Custom
}

local function GetLeadingUnderscores(str:string):number
	if EasyType(str) ~= "string" then return 0 end
	local Counter = 0
	for _, v:number in ipairs({str:byte(1,4)}) do
		if v == UnderscoreASCII then
			Counter += 1
		else
			break
		end
	end
	return Counter
end

local function CheckForMetamethod(T: { any }): never?
	for i: any, v: any in T do
		if GetLeadingUnderscores(i) == 2 then
			if MetamethodStatuses[i] then
				return error(`Metamethod {i} is forbidden`, 10)
			else
				return error(`Metamethod Prefix on {i} is forbidden`, 10)
			end
		end
	end
	return nil
end

local function CheckForBannedMetamethods(T: { any }): never?
	for i: any, v: any in T do
		if GetLeadingUnderscores(i) ~= 2 then
			return error(`Expected metamethod got {i} is not a valid metamethod`, 10)
		elseif not MetamethodStatuses[i] then
			return error(`Metamethod {i} is forbidden`, 10)
		end
	end
	return nil
end

-- Auto clean table of basic roblox instances and objects.
-- To properly clean complex custom objects assign __destroy a function to be called at the beginning of the destroy cycle.

local function SmartClose(self: { [any]: any }, Nuke: boolean)
	for i, v in self do
		local vType = EasyType(v)
		local iType = EasyType(i)

		if vType == "RBXScriptConnection" then
			(v :: RBXScriptConnection):Disconnect()
		elseif vType == "thread" then
			task.cancel(v :: thread)
		elseif vType == "table" then
			SmartClose(v, Nuke)
		elseif vType == "Instance" and Nuke then
			(v :: Instance):Destroy()
		end

		if iType == "table" then
			SmartClose(i, Nuke)
		elseif iType == "thread" then
			task.cancel(i :: thread)
		elseif iType == "RBXScriptConnection" then
			(i :: RBXScriptConnection):Disconnect()
		elseif iType == "Instance" and Nuke then
			(i :: Instance):Destroy()
		end

		self[i] = nil
	end

	table.clear(self)
    if EasyType(getmetatable(self) == "table") then
        setmetatable(self, nil)
    end
	return nil
end

local function ConcatTables(T1: { any }, T2: { any })
	for k, v in T2 do
		T1[k] = v
	end
	return T1
end

----------------------------------------------------------------------------------------------
--					 		[[ MetaData (MetaTable) ]]

-- Assigns the metamethods to the metatable
-- __index, __newindex, and __metatable are protected and cannot be written to or read
-- __tostring has a default value of 'Flag' but IS allowed to be changed and written to,

-- Flag is the string this will be printed when you try to call GetMetatable() or print with the default __tostring method.

local Metamethods = function<T, MT, MM>(self: TransferMetadata<T, MT>, Metamethods: MetaMethods<MM>, Flag: string) : T&MT
	CheckForBannedMetamethods(Metamethods :: any)
	assert(EasyType(Flag) == "string", string.format("%s Flag must be a string got %s", SERVICE_NAME, Flag))

	local MD = getmetatable(self) :: getmetatable<TransferMetadata<T,MT>>
    -- All metamethods are stored in tmp
	local Tmp = {}

	ConcatTables(Tmp, Metamethods :: any)

	local function NestedClose(...)
        if not MD.IsMetatable then
            return error(string.format("%s Userdatas are read-only and cannot be destroyed, use them for constant data as you have little control over their collection", SERVICE_NAME), 10) :: never
        end

        if (Tmp::any).__destroy then
            (Tmp.__destroy::any)(...)
        end
		SmartClose(Tmp, true)

		return SmartClose(...) :: any
	end

	Tmp.__index = function(self: { [any]: any }, index: any)
		
		if GetLeadingUnderscores(index) == 1 then
			return warn(string.format("%s %s is a private property", SERVICE_NAME, index)) :: any
		elseif index == "Destroy" then
            return NestedClose
		end
		return (MD.Metadata::{[any]:any})[index]
	end

	Tmp.__newindex = function(self: { [any]: any }, index: any, Value: any)
		if GetLeadingUnderscores(index) == 3 then
			return rawset(self, index, Value)
		end
		return error(string.format("%s table is read only", SERVICE_NAME), 10)
	end

    --[[Tmp.__tostring = function()
        return Flag
    end]]

	--Tmp.__metatable = Flag

    if MD.IsMetatable then
        return setmetatable(MD.Table, Tmp) :: any
    else
        ConcatTables(MD.Metadata, MD.Table)
        local Proxy = newproxy(true)
        local MT = getmetatable(Proxy)
        ConcatTables(MT, Tmp)

        return Proxy :: any
    end
end

----------------------------------------------------------------------------------------------

-- 							[[ Types ]]

export type MetaMethods<T> ={
	--                             [Complex functions]
	--__index: ((self:T, index:(keyof<T> | any)) -> () | {[any]:any} )?, -- self[keyof<T>] Indexes the table attached (Not the actual Metatable)
	--__newindex: ((self:T, index:any, value:any) -> () | {[any]:any})?, -- self[keyof<T>] = V Adds new value (locked for read only)
	__call: ((self: T, ...any) -> any)?, -- self() function call
	__concat: (<V>(self: T, value: V) -> T & V)?, -- self..value Concatenation (combine)
	__unm: ((self: T) -> T)?, -- -self Unary  (inverse)
	__iter: (typeof(next))?, -- Generalized iteration for K, V in self do --task-- end (Type of next as default)

	--                             [Calculations]

	__add: ((self: T, value: number) -> number)?, -- self+value Addition (Adds a number)
	__sub: ((self: T, value: number) -> number)?, -- self-value Subtraction (Subtracts a number)
	__mul: ((self: T, value: number) -> number)?, -- self*value Multiplication (Multiples a number)
	__div: ((self: T, value: number) -> number)?, -- self/value Division (Divides a number)
	__idiv: ((self: T, value: number) -> number)?, -- self//value Floor division (Floor divides a number)
	__mod: ((self: T, value: number) -> number)?, -- self%value Modulus (Modulo's by a number)
	__pow: ((self: T, value: number) -> number)?, -- self^value Exponentiation (Exponentiates a number)
	__tostring: ((self: T) -> string)?, -- tostring(self) -> printable string ()
	__len: ((self: T) -> number)?, -- #self Array length (length)

	--                          [Comparisons]

	-- Comparisons must be compared with the same basic type and if 1 calls __eq then the other must also call __eq (table, userdata are NOT compareable)
	__eq: ((self: T, value: any) -> boolean)?, -- self==value Equality operator (compares a value to be equal)

	-- Note <, > and <=, >= will both be triggered by their respective metamethods (no __gt or ge metamethod as it is redundent)
	__lt: ((self: T, value: any) -> boolean)?, -- self<value Less than operator (compares a value to be less than)
	__le: ((self: T, value: any) -> boolean)?, -- self<=value Less than or equal operator (compares a value to be less than or equal)

	--                          [constants]
	__mode: ("K" | "V" | "KV")?, -- Sets the garbage collection rule of the table
	--__metatable:string -- Locks metatable (Not editable)

    --                          [Custom]
    __destroy: ((self: T, OptionalBooleanArgument:boolean) -> ())? -- custom function to be assigned when 'Destroy is called'
    
}

type TransferMetadata<T, MT> = setmetatable<{
	WriteMetamethods: <MM>(self: TransferMetadata<T, MT>, Metamethods: MetaMethods<MM>, Flag: string) -> WrappedMetatable<T, MT>
}, {
	Table: T,
	Metadata: MT,
	IsMetatable: boolean,
}>

type WrappedMetatable<T,MT> = {
    Destroy:(self: WrappedMetatable<T,MT>, Nuke: boolean) -> nil
} & RemovePrivate<T> & RemovePrivate<MT>

type function RemovePrivate(T:type)

	for i : type, v : { read: type?, write: type? } in T:properties() do
		local index = i:value()

		local Counter = 0
		for _, vv:number in ipairs({(index::string):byte(1,4)}) do
			if vv == 95 then
				Counter += 1
			else
				break
			end
		end
		
		if Counter == 1 then
			T:setproperty(i, nil)
		elseif Counter == 2 then
			print(string.format("%s Metamethod {%s} cannot be written to Table or Metatable", "[SecureClasses]:", index::string))
		end
	end
	return T
end

----------------------------------------------------------------------------------------------

--					 		[[ Public service (constructor) ]]

-- T is the Table
-- MT is the metatable
-- Metatables are not allowed to have metamethods included when being created from NewMetatable or NewUserdata

return {
	NewMetatable = function<T, MT>(T: T, MT: MT): TransferMetadata<T, MT>
		CheckForMetamethod(T)
		CheckForMetamethod(MT)

		return setmetatable({
			["WriteMetamethods"] = Metamethods,
		}, {
			["Table"] = T,
			["Metadata"] = MT,
			["IsMetatable"] = true,
		}) :: any
	end,

	NewUserdata = function<T, MT>(T: T, MT: MT): TransferMetadata<T, MT>
        CheckForMetamethod(T)
        CheckForMetamethod(MT)

        local Proxy = newproxy(true)
        local MP = getmetatable(Proxy)

        MP.WriteMetamethods = Metamethods
        MP.Table = T
        MP.Metadata = MT
        MP.IsMetatable = false
        MP.__index = MP

        return Proxy
    end,
}

----------------------------------------------------------------------------------------------

--					 		                                    [[ Notes: ]]
--[[
            Due to the beta and testing nature of the luau type solver sometimes type intellisense will not be available due
            to the complex type casting and packing that happens throughout this class.
    

--]]

----------------------------------------------------------------------------------------------

--					 		                                    [[ Documentation: ]]


--[=[ 
	@class SecuredMetatable
	A lightweight metatable/Userdata wrapper built for security and maintain proper code edicate among custom user objects and instances with built in protections and helping features while still providing raw metatable support.
	| Syntax | Result |
	| ---- | ------- |
	| _PrivateProperty | Denotes a `Private` property **_1 Underscore_** that cannot be indexed normally `Object[Index]`. Must be manipulated with raw functions and will not be included in the type union |
	| __Metamethod | Denotes a `Metamethod` **_2 Underscores_**.  NOTE that some metamethods are assigned within the secured class and cannot be changed. IE: *__index*, *__newindex*, *__metatable* |
	| ___UnprotectedProperty | Denotes a `Free` property **_3 Underscores_**.  This property will have **NO** read or write protections |
	| RegularProperty | Denotes a `Standered` property **_4 or more Underscores_ or No Underscores**.  This is the default property that is read-only  |
	@since V 1.4.0

	### Syntax Example
	```lua
	local T = {
		["Test1"] = true, -- Creates a default property Read-Only
		["_Protected"] = true, -- Creates a Protected property Internal only
		["__Metamethod"] = "Test", -- Creates a Metamethod property must be a legal metamethod AND must be written in the metamethod table (THIS WILL ERROR)
		["___UnProtected"] = "Test", -- Creates a Unprotected property without Read and Write restrictions
	}
	```

]=]

--					Types

--[=[
	@type ProtectedMetatable (T&MT&MM)
	Table, metatable, and metamethods all linked together, metamethods are private
	@within SecuredMetatable

	:::info structure
	The `Protected Metatable` class is a read only wrapper that enacts a read only function apart of the `__newindex` metamethod, a sandboxed `__index` table, and the `__metatable` flag being enacted and is only destroyable by the `:Destroy` function.
	:::

	:::tip Property index syntax
	The `Protected Metatable` object has built in index syntax for different properties. First **Both the Table and Metatable share these syntax**. Such as: `Protected`, `Metamethod`, `UnProtected`, and `standard` syntax structures.
	:::
]=]

--[=[
	@interface MetaMethods 
	@within SecuredMetatable

	.__index ((self: T, index: (keyof(T) | any)) -> () | {[any]: any} )?, -- self[keyof(T)] Indexes the table attached (Not the actual Metatable)
	.__newindex ((self: T, index: any, value: any) -> () | {[any]: any})?, -- self[keyof(T)] = V Adds new value (locked for read only)
	.__call ((self: T, ...any) -> any)? -- self() function call
	.__concat ((self: T, value: V) -> T & V)?, -- self..value Concatenation (combine)
	.__unm ((self: T) -> T)?, -- -self Unary  (inverse)
	.__iter (typeof(next))?, -- Generalized iteration (Type of next as default)

	.__add ((self: T, value: number) -> number)?, -- self+value Addition (Adds a number)
	.__sub ((self: T, value: number) -> number)?, -- self-value Subtraction (Subtracts a number)
	.__mul ((self: T, value: number) -> number)?, -- self*value Multiplication (Multiples a number)
	.__div ((self: T, value: number) -> number)?, -- self/value Division (Divides a number)
	.__idiv ((self: T, value: number) -> number)?, -- self//value Floor division (Floor divides a number)
	.__mod ((self: T, value: number) -> number)?, -- self%value Modulus (Modulo's by a number)
	.__pow ((self: T, value: number) -> number)?, -- self^value Exponentiation (Exponentiates a number)
	.__tostring ((self: T) -> string)?, -- tostring(self) -> printable string ()
	.__len ((self: T) -> number)?, -- #self Array length (length)

	.__eq ((self: T, value: any) -> boolean)?, -- self==value Equality operator (compares a value to be equal)

	.__lt ((self: T, value: any) -> boolean)?, -- self&lt;value Less than operator (compares a value to be less than)
	.__le ((self: T, value: any) -> boolean)?, -- self&lt;=value Less than or equal operator (compares a value to be less than or equal)

	.__mode ("K" | "V" | "KV")?, -- Sets the garbage collection rule of the table
	.__metatable string -- Locks metatable 

	.__destroy ((self: T, OptionalBooleanArgument:boolean) -> ())? -- custom function to be assigned when &apos;Destroy is called&apos;

	A strongly typed metatable of all lua 5.1 metamethods + extras
	
	
	:::danger Forbidden
	Metamethods: `__index`, `__newindex`, and `__metatable` are custom and constant and cannot be written or read from. `__tostring` is the only exception as by default it is assigned to `flag` but **IS WRITABLE** when writing the metamethod table. 
	:::

	:::caution Comparisons
	`__eq`, `__lt`, `__le` Requires two values with the same metamethod function and basic type (table/userdata/etc.); does not work with a table and another random table, or with a userdata and a table.
	:::
	
	:::info New Metamethod
	`__destroy` can be assigned to be ran before the auto cleanup of `:Destroy()`.
	:::

]=]

--[=[
	@within SecuredMetatable

	@function NewMetatable
	
	@param Table T -- The front table template and inital values
	@param Metatable MT -- The metatable template and inital values

	@return TransferTable -- A read-only wrapped metatable

	Creates a new TransferMetatable object that will turn into a protected metatable
]=]

--[=[
	@within SecuredMetatable

	@function NewUserdata
	
	@param Table T -- The front table template and inital values
	@param Metatable MT -- The metatable template and inital values

	@return TransferTable -- A read-only wrapped Userdata

	Creates a new TransferMetatable object that will turn into a protected userdata

	:::caution Read-Only
	`Userdata's` are read only by default even without metamethods and cannot be destroyed apart of the 
	`:Destroy()` funtion. Calling it will result in a `error`
	:::

	:::tip Constant
	`Userdata's` are read only by default even without metamethods making them perfect for read only data.
	:::
]=]

--[=[
	@within SecuredMetatable
	@method Destroy

	The only way to destroy the metatable when flags are assigned

	@param self SecuredMetatable
	@param Nuke boolean -- Complete destroy

	@return nil

	:::info Auto clean-up
	`Destroy` contains a auto destroy function that can correctly clean up all basic `ROBLOX` objects and instances. `Nuke` is
	used when you want to destroy `instances` left `false` it will only delete the reference to the instance.
	:::

	:::tip __destroy
	The custom metamethod `__destroy` is a metamethod you can assign that will run before the auto destroy function so you can
	clean up custom complex objects. Note this DOES NOT prevent the auto destroy function from running only it runs `__destroy` before `SmartClean ":Destroy"`
	:::

	:::danger Userdata's
	`Userdata` is read only by default and CANNOT be destroyed running `:Destroy` on a userdata will result in an `error`
	:::
]=]

--[=[
	@class TransferTable
	The middle man class that transfers the templates and assigns metamethods to create a secured table object

	### Metamethods and their status
	| Metamethod | Write Safety | Read Safety |
	| ---- | --- | --- |
	| __index | **False** |  **False** |
	| __newindex | **False** | **False** |
	| __call | **True** | **False**
	| __concat | **True** | **False** |
	| __unm | **True** | **False** |
	| __add | **True** | **False** |
	| __sub | **True** | **False** |
	| __mul | **True** | **False** |
	| __div | **True** | **False** |
	| __idiv | **True** | **False** |
	| __mod | **True** | **False** |
	| __pow | **True** | **False** |
	| __tostring | **True** | **True** |
	| __metatable | **False** | **True** |
	| __eq | **True** | **False** |
	| __lt | **True** | **False** |
	| __le | **True** | **False** |
	| __mode | **True** | **False** |
	| __len | **True** | **False** |
	| __iter | **True** | **False** |
	| __destroy | **True** | **False** |


]=]
--					Types

--[=[
	@interface TransferMetatable 
	@within TransferTable
	@tag ReadOnly

	.Table T -- Front table template
	.Metatable MT -- Metatable template
	.IsMetatable boolean

	Middle man object with all its data stored inside of its metatable

]=]

--[=[
	@method WriteMetamethods
	@within TransferTable

	@param self TransferMetatable
	@param Metamethods MetaMethods
	@param Flag string -- string assigned to `__metatable`

	@return ProtectedMetatable

	Compiles the protected metatable with its protected metamethods
	
]=]