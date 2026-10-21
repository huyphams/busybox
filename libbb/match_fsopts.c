/* vi: set sw=4 ts=4: */
/*
 * Match fsopts for use in mount unmount -O.
 *
 * Returns 1 for a match, otherwise 0.
 *
 * Licensed under GPLv2 or later, see file LICENSE in this source tree.
 */

#include "libbb.h"

static int fsopt_matches(const char *opts_list, const char *opt, size_t optlen)
{
	int match = 1;

	if (optlen >= 2 && opt[0] == 'n' && opt[1] == 'o') {
		match--;
		opt += 2; optlen -= 2;
	}

	/* The alone "no" is an error, all matching ends with False. */
	if (optlen == 0)
		return 0;

	/* The "no" prefix interpretation can be disabled by the "+" prefix. */
	if (match && optlen > 1 && *opt == '+') {
		opt++; optlen--;
	}

	while (1) {
		if (strncmp(opts_list, opt, optlen) == 0) {
			const char *after_opt = opts_list + optlen;
			if (*after_opt == '\0' || *after_opt == ',')
				return match;
		}

		opts_list = strchr(opts_list, ',');
		if (!opts_list)
			break;
		opts_list++;
	}

	return !match;
}

/* This function implements the mnt_match_options function from libmount. */
int FAST_FUNC fsopts_matches(const char *opts_list, const char *reqopts_list)
{
	if (!reqopts_list)
		return 1; /* no options requested, match anything */

	while (1) {
		size_t len;
		const char *comma = strchr(reqopts_list, ',');
		if (!comma)
			len = strlen(reqopts_list);
		else
			len = comma - reqopts_list;

		if (len && !fsopt_matches(opts_list, reqopts_list, len))
			return 0;

		if (!comma)
			break;
		reqopts_list = ++comma;
	}

	return 1;
}
