#include <stdio.h>
#include <stdbool.h>
#include <msgpuck.h>

#include "module.h"

/*
 * Sum two integers.
 */
int
cfunc_add(box_function_ctx_t *ctx, const char *args, const char *args_end)
{
	uint32_t arg_count = mp_decode_array(&args);
	if (arg_count != 2) {
		return box_error_set(__FILE__, __LINE__, ER_PROC_C, "%s",
				     "invalid argument count");
	}
	uint64_t a = mp_decode_uint(&args);
	uint64_t b = mp_decode_uint(&args);

	char res[16];
	char *end = mp_encode_uint(res, a + b);
	box_return_mp(ctx, res, end);
	return 0;
}
