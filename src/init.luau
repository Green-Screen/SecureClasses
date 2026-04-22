-- SecureClasses V 1.1.0
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

local function CheckForMetamethod(T: { any }): never?
	for i: any, v: any in T do
		if type(i) == "string" then
			if (i :: string):find("__", 1, true) then
				return error(`Metamethod {i} is forbidden`, 2)
			end
		end
	end
	return nil
end

local function InverseCheckForMetamethods(T: { any }): never?
	for i: any, v: any in T do
		if type(i) == "string" then
			if not (i :: string):find("__", 1, true) then
				return error(`Expected metamethod got {i} is forbidden`, 2)
			end
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
	InverseCheckForMetamethods(Metamethods :: any)
	assert(EasyType(Flag) == "string", string.format("%s Flag must be a string got %s", SERVICE_NAME, Flag))

	local MD = getmetatable(self) :: getmetatable<TransferMetadata<T,MT>>
    -- All metamethods are stored in tmp
	local Tmp = {}

	ConcatTables(Tmp, Metamethods :: any)

	local function NestedClose(...)
        if not MD.IsMetatable then
            return error(string.format("%s Userdatas are read-only and cannot be destroyed, use them for constant data as you have little control over their collection", SERVICE_NAME),6) :: never
        end

        if (Tmp::any).__destroy then
            (Tmp.__destroy::any)(...)
        end
		SmartClose(Tmp, true)

		return SmartClose(...) :: any
	end

	Tmp.__index = function(self: { [any]: any }, index: any)
		if index == "Destroy" then
            return NestedClose
		end
		return (MD.Metadata::{[any]:any})[index]
	end

	Tmp.__newindex = function()
		return error(string.format("%s table is read only", SERVICE_NAME))
	end

    Tmp.__tostring = function()
        return Flag
    end

	Tmp.__metatable = Flag

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
} & T & MT

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


--- @class SecuredMetatable
--- A lightweight metatable/Userdata wrapper built for security and maintain proper code edicate among custom user objects and instances with built in protections and helping features while still providing raw metatable support.

--					Types

--[=[
	@type SecuredMetatable<T,MT, MM> (T&MT&MM)
	@within SecuredMetatable
	:::info
	The `Secured Metatable` class is a ready only wrapper that enacts a read only function apart of the `__newindex` metamethod, a sandboxed `__index` table, and the `__metatable` flag being enacted and is only destroyable by the `:Destroy` function.
	:::
]=]

--[=[
	@interface MetaMethods<T> -- Strongly typed metamethods
	@within SecuredMetatable

	.__index ((self:T, index:(keyof<T> | any)) -> () | {[any]:any} )?, -- self[keyof<T>] Indexes the table attached (Not the actual Metatable)
	.__newindex ((self:T, index:any, value:any) -> () | {[any]:any})?, -- self[keyof<T>] = V Adds new value (locked for read only)
	.__call ((self: T, ...any) -> any)? -- self() function call
	.__concat (<V>(self: T, value: V) -> T & V)?, -- self..value Concatenation (combine)
	.__unm ((self: T) -> T)?, -- -self Unary  (inverse)
	.__iter (typeof(next))?, -- Generalized iteration for K, V in self do --task-- end (Type of next as default)

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

	.__lt ((self: T, value: any) -> boolean)?, -- self<value Less than operator (compares a value to be less than)
	.__le ((self: T, value: any) -> boolean)?, -- self<=value Less than or equal operator (compares a value to be less than or equal)

	.__mode ("K" | "V" | "KV")?, -- Sets the garbage collection rule of the table
	.__metatable string -- Locks metatable 

	.__destroy ((self: T, OptionalBooleanArgument:boolean) -> ())? -- custom function to be assigned when 'Destroy is called'
	
	
	:::danger Forbidden
	Metamethods: `__index`, `__newindex`, and `__metatable` are custom and constant and cannot be written or read from.
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

	@function NewMetatable<T, MT>
	
	@param Table T -- The front table template and inital values
	@param Metatable MT -- The metatable template and inital values

	@return TransferTable<T, MT> -- A read-only wrapped metatable
]=]

--[=[
	@within SecuredMetatable

	@function NewUserdata<T, MT>
	
	@param Table T -- The front table template and inital values
	@param Metatable MT -- The metatable template and inital values

	@return TransferTable<T, MT> -- A read-only wrapped Userdata

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

	@param self SecuredMetatable<T, MT>
	@param Nuke boolean -- Complete destroy

	@return nil

	:::info Auto clean-up
	`Destroy` contains a auto destroy function that can correctly clean up all basic `ROBLOX` objects and instances. `Nuke` is
	used when you want to destroy `instances` left `false` it will only delete the reference to the instance.
	:::
	:::tip __destroy
	The custom metamethod `__destroy` is a metamethod you can assign that will run before the auto destroy function so you can
	clean up custom complex objects. Note this DOES NOT prevent the auto destroy function from running only it runs `__destroy` before `SmartClean`
	:::
	:::danger Userdata's
	`Userdata` is read only by default and CANNOT be destroyed running `:Destroy` on a userdata will result in an `error`
	:::
]=]

--- @class TransferTable
--- The middle man class that transfers the templates and assigns metamethods to create a secured table object 

--[=[
	@interface TransferMetatable<T, MT>
	@within TransferTable

	.Table T -- Front table template
	.Metatable MT -- Metatable template
	.IsMetatable boolean

]=]

--[=[
	@method WriteMetamethods<T, MT, MM>
	@within TransferTable

	@param self TransferMetatable<T, MT>
	@param Metamethods MetaMethods<MM>
	@param Flag string -- string assigned to `__metatable`

	
]=]