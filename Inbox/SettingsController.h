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

#import <UIKit/UIKit.h>

@class DeskController;
@class MBProgressHUD;

@interface SettingsController : UIViewController{
    
    IBOutlet UILabel *inboxCountLabel;
    IBOutlet UILabel *inboxCountValue;
    IBOutlet UILabel *lastSyncValue;
    IBOutlet UILabel *lastSyncLabel;
    IBOutlet UILabel *accountValue;
    IBOutlet UILabel *accountLabel;
    DeskController* desk;
    MBProgressHUD* hud;
    BOOL resync;
}
@property(nonatomic,retain) DeskController* desk;
- (IBAction)sync:(id)sender;
- (IBAction)editAccount:(id)sender;
-(void)linkToModel;
-(void)unlinkToModel;
@end
