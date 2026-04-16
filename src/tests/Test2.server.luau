local SecureClasses = require("../")

local T = SecureClasses.NewMetatable({["Test1"] = true}, {["Test2"] = false})

print(T, getmetatable(T))

local Tmp = {["__len"] = function<K,V>(self:{ [K]: V }) 
    return 5
end}

local metaTable = T:WriteMetamethods(Tmp, "Test")

print(metaTable, getmetatable(metaTable))

table.clear(Tmp)

print(metaTable.Test2)

print(metaTable.Destroy)

print(metaTable, getmetatable(metaTable))

print(#metaTable)

metaTable:Destroy()

print(metaTable, getmetatable(metaTable))

print(#metaTable)