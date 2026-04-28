--!strict
warn("USERDATA TEST ACTIVE")

-- Userdata Test
local SecureClasses = require("../")

local T = {
    ["Test1"] = true
}

local MT = {
    ["Test2"] = false,
    ["_Private"] = "Private"
}


type tabletype = {["Test1"]:boolean} & {["Test2"]:boolean}

local TransferProxy = SecureClasses.NewUserdata(T, MT)

local Metamethods:SecureClasses.MetaMethods<tabletype> = {
    __unm = function(s)
        s.Test1 = not s.Test1
        s.Test2 = not s.Test2
        return s
    end,

    __concat = function<V>(s, v:V)
        for i:any, k:any in v::any do
            (s::any)[i] = k
        end
        return s :: any
    end,

    __destroy = function(s)
        warn("Destroying class")
    end,

}


local Userdata = TransferProxy:WriteMetamethods(Metamethods, "Protected Proxy")

-- Ok
print(Userdata.Test1)
print(Userdata.Test2)

-- Not ok
print(Userdata.Test3)
print(Userdata._Private)

-- Will lock table and metatable with flag
-- table can be overwritten with __tostring metamethod
print(Userdata, getmetatable(Userdata))

-- Not ok will error, Userdata's are read only by default
--MetaTable.Test2 = nil

-- Userdatas are static and cannot be changed 'will error'
Userdata:Destroy(true)