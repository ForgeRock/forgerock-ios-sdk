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

/*************************************************************************
 * Base32 encode and decode functions.
 *
 * Padding:
 * The RFC defines that encoding is performed in quantums of 8 encoded
 * characters. If the output string is less than a full quantum, it
 * will be padded with the '=' character to make a full quantum.
 *
 * Return/Error:
 * All functions return the number of output bytes or -1 on error.
 *
 * Buffer:
 * If the output buffer is too small, the result will silently be truncated.
 *************************************************************************/


#import <string.h>
#import "base32.h"

/*************************************************************************
 * Decode a base32 encoded string into the provided buffer.
 *
 * Encoded input string to decode can include white-space and hyphens
 * which will be ignored. All other characters are considered invalid.
 *
 * Handles padding symbols at the end of the encoded input string.
 *
 * Parameters:
 *   encoded - A null terminated char* containing the encoded base32
 *   result - An initialised buffer to contain the decoded result
 *   bufSize - The size of the initialised buffer
 *
 * Return:
 *   A count of length of the decoded string
 *************************************************************************/
int base32_decode(const char *encoded, uint8_t *result, int bufSize) {
    int buffer = 0;
    int bitsLeft = 0;
    int count = 0;

    for (; count < bufSize && *encoded; ++encoded) {
        char ch = *encoded;
        if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' || ch == '-' || ch == '=') {
            continue;
        }
        buffer <<= 5;
        
        // Deal with commonly mistyped characters
        if (ch == '0') {
            ch = 'O';
        } else if (ch == '1') {
            ch = 'L';
        } else if (ch == '8') {
            ch = 'B';
        }
        
        // Look up one base32 digit
        if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')) {
            ch = (ch & 0x1F) - 1;
        } else if (ch >= '2' && ch <= '7') {
            ch -= '2' - 26;
        } else {
            return -1;
        }
        
        buffer |= ch;
        bitsLeft += 5;
        if (bitsLeft >= 8) {
            result[count++] = buffer >> (bitsLeft - 8);
            bitsLeft -= 8;
        }
    }

    if (count < bufSize) {
        result[count] = '\000';
    }

    return count;
}

/*********************************************************************************
 * Encode a string with base32 encoding into the provided buffer.
 *
 * If the encoded string does not make up a complete quantum of encoded characters
 * then padding symbols will be included accordingly.
 *
 * Parameters:
 *   data - A possibly null terminated buffer containing the characters to encode
 *   length - The number of characters in 'data'
 *   result - A pre-initialised buffer to store the encoded characters in
 *   bufSize - The size of the 'result' buffer
 *
 * Return:
 *   A count of length of the encoded string
 *
 *********************************************************************************/
int base32_encode(const uint8_t *data, int length, char *result, int bufSize) {
    int count = 0;
    int quantum = 8;

    if (length < 0 || length > (1 << 28)) {
        return -1;
    }

    if (length > 0) {
        int buffer = data[0];
        int next = 1;
        int bitsLeft = 8;

        while (count < bufSize && (bitsLeft > 0 || next < length)) {
            if (bitsLeft < 5) {
                if (next < length) {
                    buffer <<= 8;
                    buffer |= data[next++] & 0xFF;
                    bitsLeft += 8;
                } else {
                    int pad = 5 - bitsLeft;
                    buffer <<= pad;
                    bitsLeft += pad;
                }
            }

            int index = 0x1F & (buffer >> (bitsLeft - 5));
            bitsLeft -= 5;
            result[count++] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"[index];
            
            // Track the characters which make up a single quantum of 8 characters
            quantum--;
            if (quantum == 0) {
                quantum = 8;
            }
        }
        
        // If the number of encoded characters does not make a full quantum, insert padding
        if (quantum != 8) {
            while (quantum > 0 && count < bufSize) {
                result[count++] = '=';
                quantum--;
            }
        }
    }
    
    // Finally check if we exceeded buffer size.
    if (count < bufSize) {
        result[count] = '\000';
        return count;
    } else {
        return -1;
    }
}