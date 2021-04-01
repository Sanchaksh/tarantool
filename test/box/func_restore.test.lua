--
-- Test that function can be restored to the
-- former values when new module can't be
-- loaded for some reason (say there some
-- missing functions).
--
build_path = os.getenv("BUILDDIR")
package.cpath = build_path..'/test/box/?.so;'..build_path..'/test/box/?.dylib;'..package.cpath

fio = require('fio')

ext = (jit.os == "OSX" and "dylib" or "so")

path_func_restore = fio.pathjoin(build_path, "test/box/func_restore.") .. ext
path_func_good = fio.pathjoin(build_path, "test/box/func_restore1.") .. ext
path_func_bad = fio.pathjoin(build_path, "test/box/func_restore2.") .. ext

_ = pcall(fio.unlink(path_func_restore))
fio.symlink(path_func_good, path_func_restore)

box.schema.func.create('func_restore.echo_1', {language = "C"})
box.schema.func.create('func_restore.echo_2', {language = "C"})
box.schema.func.create('func_restore.echo_3', {language = "C"})

box.schema.user.grant('guest', 'execute', 'function', 'func_restore.echo_3')
box.schema.user.grant('guest', 'execute', 'function', 'func_restore.echo_2')
box.schema.user.grant('guest', 'execute', 'function', 'func_restore.echo_1')

-- Order *does* matter since we bind functions in
-- a list where entries are added to the top.
box.func['func_restore.echo_3']:call()
box.func['func_restore.echo_2']:call()
box.func['func_restore.echo_1']:call()

_ = pcall(fio.unlink(path_func_restore))
fio.symlink(path_func_bad, path_func_restore)

ok, _ = pcall(box.schema.func.reload, "func_restore")
assert(not ok)

box.func['func_restore.echo_1']:call()
box.func['func_restore.echo_2']:call()
box.func['func_restore.echo_3']:call()
