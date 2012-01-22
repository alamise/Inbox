/*
 *
 * Copyright (c) 2012 Simon Watiau.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "FolderModel.h"


@implementation FolderModel
static NSMutableArray* ORDER;
@dynamic path;


+(void)initialize{
    ORDER = [[NSMutableArray alloc] init];
    [ORDER addObject:NSLocalizedString(@"folderModel.path.archives", @"Localized Archives folder's path en: \"[Gmail]/All Mail\"")];
    [ORDER addObject:NSLocalizedString(@"folderModel.path.starred", @"Localized Starred folder's path en:\"[Gmail]/Starred\"")];
    [ORDER addObject:NSLocalizedString(@"folderModel.path.important", @"Localized Important folder's path en:\"[Gmail]/Important\"")];
    [ORDER addObject:NSLocalizedString(@"folderModel.path.spam", @"Localized Spam folder's path en:\"[Gmail]/Spam\"")];
    [ORDER addObject:NSLocalizedString(@"folderModel.path.trash", @"Localized Trash folder's path en:\"[Gmail]/Trash\"")];
}

+(NSString*)entityName{
    return @"Folder";
}

- (NSComparisonResult) compare:(FolderModel*) other{
    
    int myPos = [ORDER indexOfObject:self.path];
    int itsPos = [ORDER indexOfObject:other.path];
    
    if ((myPos!=NSNotFound)&&(itsPos!=NSNotFound)){
        if (myPos>itsPos){
            return NSOrderedDescending;
        }else if (myPos<itsPos){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    }else if (myPos!=NSNotFound && itsPos==NSNotFound){
        return NSOrderedAscending;
    }else if (myPos==NSNotFound && itsPos!=NSNotFound){
        return NSOrderedDescending;
    }else {
        return NSOrderedAscending;
    }
}
@end
