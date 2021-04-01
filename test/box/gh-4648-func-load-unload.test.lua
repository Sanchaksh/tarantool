fiber = require('fiber')
test_run = require('test_run').new()
build_path = os.getenv("BUILDDIR")
package.cpath = build_path..'/test/box/?.so;'..build_path..'/test/box/?.dylib;'..package.cpath
errinj = box.error.injection

--
-- gh-4648: box.schema.func.drop() didn't unload a .so/.dylib
-- module. Even if it was unused already. Moreover, recreation of
-- functions from the same module led to its multiple mmaping.
--

current_module_count = errinj.get("ERRINJ_DYN_MODULE_COUNT")
function check_module_count_diff(diff)                          \
    local module_count = errinj.get("ERRINJ_DYN_MODULE_COUNT")  \
    current_module_count = current_module_count + diff          \
    if current_module_count ~= module_count then                \
        return current_module_count, module_count               \
    end                                                         \
end

-- Module is not loaded until any of its functions is called first
-- time.
box.schema.func.create('function1', {language = 'C'})
check_module_count_diff(0)
box.schema.func.drop('function1')
check_module_count_diff(0)

-- Module is unloaded when its function is dropped, and there are
-- no not finished invocations of the function.
box.schema.func.create('function1', {language = 'C'})
check_module_count_diff(0)
box.func.function1:call()
check_module_count_diff(1)
box.schema.func.drop('function1')
check_module_count_diff(-1)

-- A not finished invocation of a function from a module prevents
-- low level module intance unload while schema level module is
-- free to unload immediately when dropped.
box.schema.func.create('function1', {language = 'C'})
box.schema.func.create('function1.test_sleep', {language = 'C'})
check_module_count_diff(0)

function long_call() box.func['function1.test_sleep']:call() end
f1 = fiber.create(long_call)
f2 = fiber.create(long_call)
test_run:wait_cond(function()                                   \
    return f1:status() == 'suspended' and                       \
        f2:status() == 'suspended'                              \
end)
box.func.function1:call()
check_module_count_diff(1)
box.schema.func.drop('function1')
box.schema.func.drop('function1.test_sleep')
check_module_count_diff(-1)

f1:cancel()
test_run:wait_cond(function() return f1:status() == 'dead' end)
check_module_count_diff(0)

f2:cancel()
test_run:wait_cond(function() return f2:status() == 'dead' end)
check_module_count_diff(0)
