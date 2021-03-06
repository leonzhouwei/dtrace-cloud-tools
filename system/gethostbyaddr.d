#!/usr/sbin/dtrace -s
/*
 * gethostbyaddr.d - snoop gethostbyaddr_r() calls with IP and latency.
 *
 * This can be used for the analysis of DNS latency, for apps that are
 * making this call.
 *
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
 *
 * You can obtain a copy of the license at http://smartos.org/CDDL
 *
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file.
 *
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 *
 * Copyright (c) 2012 Joyent Inc., All rights reserved.
 * Copyright (c) 2012 Brendan Gregg, All rights reserved.
 */

#pragma D option defaultargs

dtrace:::BEGIN
{
	printf("Tracing gethostbyaddr_r() longer than %d ms...\n", $1);
	min_ns = $1 * 1000000;
}

pid$target::gethostbyaddr_r:entry
{
	self->s = timestamp;
	self->n = inet_ntoa(copyin(arg0, arg1));
}

pid$target::gethostbyaddr_r:return
/self->s && (this->lat = (timestamp - self->s)) && this->lat > min_ns/
{
	printf("%d ms for \"%s\"", (this->lat) / 1000000, self->n);
}

pid$target::gethostbyaddr_r:return
/self->s/
{
	self->s = 0;
	self->n = 0;
}
