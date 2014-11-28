#import "AppDelegate.h"
#import "GSKTestController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];

    GSKTestController *test = [[GSKTestController alloc] init];
    //UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:test];
    self.window.rootViewController = test;

    [self.window makeKeyAndVisible];
    return YES;
}

@end
