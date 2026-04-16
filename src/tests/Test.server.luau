--[[task.spawn(function()
    while task.wait() do
        print(gcinfo())
    end
end)]]

local SecureClasses = require("../")
local TestClass = SecureClasses({ ["Test3"] = true }, { ["Test"] = true }, "Protected")

print(TestClass, getmetatable(TestClass))

-- True
print(TestClass.Test)

-- nil
print(TestClass.Test2)

--local tmp = TestClass["Destroy"]
TestClass:Destroy()
print(TestClass)

-- Error as its modifying the metatable
--TestClass.Test3 = 200
--print(TestClass.Test3)

-- Error
--TestClass.Test2 = false
--print(getmetatable(TestClass))

print(TestClass["Test"])