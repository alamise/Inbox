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
@interface FolderModel(){
}
@end

@implementation FolderModel
@dynamic path;
@dynamic account;
@dynamic emails;

+(void)initialize{
    
}

+(NSString*)entityName{
    return @"Folder";
}

- (NSComparisonResult) compare:(FolderModel*) other{
    NSMutableArray* order = [[NSMutableArray alloc] init];
    [order addObject:NSLocalizedString(@"folderModel.path.archives", @"Localized Archives folder's path en: \"[Gmail]/All Mail\"")];
    [order addObject:NSLocalizedString(@"folderModel.path.starred", @"Localized Starred folder's path en:\"[Gmail]/Starred\"")];
    [order addObject:NSLocalizedString(@"folderModel.path.important", @"Localized Important folder's path en:\"[Gmail]/Important\"")];
    [order addObject:NSLocalizedString(@"folderModel.path.spam", @"Localized Spam folder's path en:\"[Gmail]/Spam\"")];
    [order addObject:NSLocalizedString(@"folderModel.path.trash", @"Localized Trash folder's path en:\"[Gmail]/Trash\"")];
    int myPos = [order indexOfObject:self.path];
    int itsPos = [order indexOfObject:other.path];
    [order release];
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


-(NSString*)hrTitle{
    NSString* str = self.path;
    if ([path hasPrefix:@"[Gmail]/"]){
        str = [path substringFromIndex:8];
    }
    if ([str isEqualToString:@"All Mail"]){
        return @"Archive";
    }
    return str;
}
@end
