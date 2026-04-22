# WorkFlows
:::caution
When writing metamethods that interact with the main class be sure to use it's raw function to prevent C stack overflows such as `rawset`, `rawget`, `rawlen`, `rawequal`
:::
:::tip
`Userdata's` are almost identical to metatables but are limited as they are permanently read-only and should only be used for constant data that needs to be protected.
:::

### Wrapped Metatable

#### 1. Creating Transfer class
```lua
--!strict

-- Metatable test
local SecureClasses = require("../")

-- Front table
local T = {
    ["Test1"] = true
}

-- Metatable
local MT = {
    ["Test2"] = false,
    UpdateTest1 = function(self:any, NewValue:any)
        rawset(self, "Test2", NewValue)
    end
}

-- Simple optional type just to help out the type solver
type tabletype = {["Test1"]:boolean} & {["Test2"]:boolean}

-- Creates a transfer table object
local TransferTable = SecureClasses.NewMetatable(T, MT)
```

### 2. Assign metamethods
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

local Metamethods:SecureClasses.MetaMethods<tabletype> = {
    -- Uranary metamethod
    __unm = function(s)
        s.Test1 = not s.Test1
        s.Test2 = not s.Test2
        return s
    end,

    -- Concatenation metamethod
    __concat = function<V>(s, v:V)
        for i:any, k:any in v::any do
            (s::any)[i] = k
        end
        return s :: any
    end,

    -- Destroy metamethod
    __destroy = function(s)
        warn("Destroying class")
    end,

}

-- Creates a WrappedMetatable class that function the same as a regular metatable
-- Table is Read-Only
local MetaTable = TransferTable:WriteMetamethods(Metamethods, "Protected Metatable")
```

### 3. Basic indexing and writing
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

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
```

### 4. Destroy
```lua
--!strict
-- Having strict enabled will allow the type solver to lint your metamethod table more accuratly

-- Destroy with nuke
MetaTable:Destroy(true)

-- Not Ok
print(MetaTable.Test1)
print(MetaTable.Test2)

-- Empty
print(MetaTable, getmetatable(MetaTable))
```