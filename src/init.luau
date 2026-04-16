-- SecureClasses V 1.0.0
-- @Patriots8800

--!strict

----------------------------------------------------------------------------------------------

-- 							[[ Dependencies ]]
local EasyType = require("./SecureClasses/Dependencies/EasyType")

----------------------------------------------------------------------------------------------


-- 							[[ Service Header ]]

local SERVICE_NAME = "[SecureClasses]:"


----------------------------------------------------------------------------------------------

-- 							[[ Private functions (helpers) ]]

local function CheckForMetamethod(T: { [any]: any }): never?
	for i: any, v: any in T do
		if type(i) == "string" then
			if (i::string):find("__", 1, true) then
				return error(`Metamethod {i} is forbidden`, 2)
			end
		end
	end
	return nil
end

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
	
	return nil
end

----------------------------------------------------------------------------------------------
--					 		[[ MetaData (MetaTable) ]]

local Metamethods = function(self:{[any]:any}, MetaMethods:{[string]:any})
    
end



----------------------------------------------------------------------------------------------

-- 							[[ Types ]]

type MetaMethods<T> = {
    --                             [Complex functions]
    __index: ((self:T, index:(keyof<T> | any)) -> () ), -- self[keyof<T>] Indexes the table attached (Not the actual Metatable)
    __newindex: ((self:T, index:any, value:any) -> () | {[any]:any}), -- self[keyof<T>] = V Adds new value (locked for read only)
    __call: (self:T, ...any) -> any, -- self() function call
    __concat: <V>(self:T, value:V) -> T&V, -- self..value Concatenation (combine)
    __unm: (self:T) -> T, -- -self Unary  (inverse)
    __iter: typeof(next), -- Generalized iteration for K, V in self do --task-- end (Type of next as default)

    --                             [Calculations]

    __add: (self:T, value:number) -> number, -- self+value Addition (Adds a number)
    __sub: (self:T, value:number) -> number, -- self-value Subtraction (Subtracts a number)
    __mul: (self:T, value:number) -> number, -- self*value Multiplication (Multiples a number)
    __div: (self:T, value:number) -> number, -- self/value Division (Divides a number)
    __idiv: (self:T, value:number) -> number, -- self//value Floor division (Floor divides a number)
    __mod: (self:T, value:number) -> number, -- self%value Modulus (Modulo's by a number)
    __pow: (self:T, value:number) -> number, -- self^value Exponentiation (Exponentiates a number)
    __tostring: (self:T) -> string, -- tostring(self) -> printable string ()
    __len: (self:T) -> number, -- #self Array length (length)

    --                          [Comparisons]

    -- Comparisons must be compared with the same basic type and if 1 calls __eq then the other must also call __eq (table, userdata are NOT compareable)
    __eq: (self:T, value:any) -> boolean, -- self==value Equality operator (compares a value to be equal)

    -- Note <, > and <=, >= will both be triggered by their respective metamethods (no __gt or ge metamethod as it is redundent)
    __lt: (self:T, value:any) -> boolean, -- self<value Less than operator (compares a value to be less than)
    __le: (self:T, value:any) -> boolean, -- self<=value Less than or equal operator (compares a value to be less than or equal)

    --                          [constants]
    __mode: "K"|"V"|"KV"
    --__metatable:string -- Locks metatable (Not editable)

}

local T:MetaMethods<typeof({["Test"] = true})>

T.__index = function(self:{ Test: boolean }, Value:"Test" | any)
    
end
----------------------------------------------------------------------------------------------

--					 		[[ Public service (constructor) ]]

return {
    NewMetatable = function(T: { [any]: any }, MT: { [any]: any })
        
    end,

    NewUserdata = function()
        
    end
}

----------------------------------------------------------------------------------------------