//
//  JBUtil.c
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

#include "JBUtil.h"

#import <sys/stat.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <unistd.h>


bool validate_sandbox() {
    int result = fork();
    if (!result)  /* The child should exit, if it spawned */
        return false;
    
    if (result >= 0) { /* If the fork succeeded, we're jailbroken */
        return true;
    }
    else {
        return false;
    }
}

bool validate_dyld()
{
    // load and interate all dyld
    int i=0;
    while(true) {
        // Validate know substrate lib
        const char *dyld = _dyld_get_image_name(i++);
        if (dyld == NULL) {
            break;
        }
        if(!strstr(dyld, "MobileSubstrate") && !strstr(dyld, "libsubstrate") && !strstr(dyld, "SubstrateInserter")) {
            continue;
        }
        else {
            return true;
        }
    }
    return false;
}
