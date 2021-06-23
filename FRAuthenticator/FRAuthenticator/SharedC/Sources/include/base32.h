/*
 * The contents of this file are subject to the terms of the Common Development and
 * Distribution License (the License). You may not use this file except in compliance with the
 * License.
 *
 * You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
 * specific language governing permission and limitations under the License.
 *
 * When distributing Covered Software, include this CDDL Header Notice in each file and include
 * the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
 * Header, with the fields enclosed by brackets [] replaced by your own identifying
 * information: "Portions copyright [year] [name of copyright owner]".
 *
 * Copyright 2015-2016 ForgeRock AS.
 *
 * Portions Copyright 2010 Markus Gutschke, Google Inc.
 */

/***********************************************************************
 * Encode and decode Base32 based on the RFC 4648
 * (http://tools.ietf.org/html/rfc4648)
 *
 * String to be encoded is assumed to be ASCII characters.
 *
 * Encoded output will consist of the following alphabet:
 * "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
 ***********************************************************************/

#ifndef _BASE32_H_
#define _BASE32_H_
#import <stdint.h>
int __attribute__((visibility("default")))
base32_decode(const char *encoded, uint8_t *result, int bufSize);

int __attribute__((visibility("default")))
base32_encode(const uint8_t *data, int length, char *result, int bufSize);
#endif /* _BASE32_H_ */
