local TraceRouteService = game:GetService("TraceRouteService")
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

local AllowedMetaMethods = {
    ["__index"] = true,
    ["__newindex"] = true,
    ["__call"] = true,
    ["__concat"] = true,
    ["__unm"] = true,
    ["__add"] = true,
    ["__sub"] = true,
    ["__mul"] = true,
    ["__div"] = true,
    ["__idiv"] = true,
    ["__mod"] = true,
    ["__pow"] = true,
    ["__tostring"] = true,
    --["__metatable"] = false,
    ["__eq"] = true,
    ["__lt"] = true,
    ["__le"] = true,
    ["__mode"] = true,
    ["__len"] = true,
    ["__iter"] = true
}

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

local function InverseCheckForMetamethods(T: { [any]: any }): never?
    for i: any, v: any in T do
		if type(i) == "string" then
			if not (i::string):find("__", 1, true) then
				return error(`Expected metamethod got {i} is forbidden`, 2)
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

    table.clear(self)
	return nil
end

local function ConcatTables(T1, T2)
    for k, v in T2 do
        T1[k] = v
    end
    return T1
end

----------------------------------------------------------------------------------------------
--					 		[[ MetaData (MetaTable) ]]

local Metamethods = function<K,V, A, B>(self:{[K]:V}, Metamethods:MetaMethods<{[A]:B}>, Flag:string)
    InverseCheckForMetamethods(Metamethods)
    assert(EasyType(Flag) == "string", string.format("%s Flag must be a string got %s", SERVICE_NAME, Flag))

    local MD = getmetatable(self)
    local Tmp = {}

    ConcatTables(Tmp, Metamethods)

    local function NestedClose(...)
        SmartClose(Tmp, true)
        return SmartClose(...)
    end

    
    Tmp.__index = function(self:{ [any]:any }, index: any)
        if index == "Destroy" then
            return NestedClose
        end
        return MD.Metadata[index]
    end

    Tmp.__newindex = function()
        return error("Table is read only")
    end

    --Tmp.__metatable = Flag

    return setmetatable(MD.Table, Tmp)
end



----------------------------------------------------------------------------------------------

-- 							[[ Types ]]

--type tmp = keyof<typeof(AllowedMetaMethods)>


export type MetaMethods<T> = {
    --                             [Complex functions]
    --__index: ((self:T, index:(keyof<T> | any)) -> () ), -- self[keyof<T>] Indexes the table attached (Not the actual Metatable)
    --__newindex: ((self:T, index:any, value:any) -> () | {[any]:any}), -- self[keyof<T>] = V Adds new value (locked for read only)
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
    __len: <K,V>(self:T) -> number, -- #self Array length (length)

    --                          [Comparisons]

    -- Comparisons must be compared with the same basic type and if 1 calls __eq then the other must also call __eq (table, userdata are NOT compareable)
    __eq: (self:T, value:any) -> boolean, -- self==value Equality operator (compares a value to be equal)

    -- Note <, > and <=, >= will both be triggered by their respective metamethods (no __gt or ge metamethod as it is redundent)
    __lt: (self:T, value:any) -> boolean, -- self<value Less than operator (compares a value to be less than)
    __le: (self:T, value:any) -> boolean, -- self<=value Less than or equal operator (compares a value to be less than or equal)

    --                          [constants]
    __mode: "K"|"V"|"KV" -- Sets the garbage collection rule of the table
    --__metatable:string -- Locks metatable (Not editable)

}

type Destroy = (self:{[any]:any}, Nuke:boolean) -> nil

----------------------------------------------------------------------------------------------

--					 		[[ Public service (constructor) ]]

return {
    NewMetatable = function<A,B,C,D>(T: { [A]: B }, MT: { [C]: D })
        CheckForMetamethod(T)
        CheckForMetamethod(MT)

        return setmetatable({["WriteMetamethods"] = Metamethods}, {
            ["Table"] = T,
            ["Metadata"] = MT
        })
    end,

    NewUserdata = function()
        
    end
}

----------------------------------------------------------------------------------------------