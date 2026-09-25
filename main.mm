#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>
#include <cstdlib>
#include <objc/runtime.h>

static const void *DuskContextMenuKey = &DuskContextMenuKey;

@interface DuskStatusButton : NSStatusBarButton
@end

@implementation DuskStatusButton

- (void)rightMouseDown:(NSEvent *)event {
  NSMenu *menu = objc_getAssociatedObject(self, DuskContextMenuKey);

  if (menu) {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    [menu popUpMenuPositioningItem:nil atLocation:location inView:self];
  }
}

@end

@interface DuskController : NSObject <NSApplicationDelegate>

@property(nonatomic, strong) NSWindow *overlay;
@property(nonatomic, strong) NSPopover *popover;
@property(nonatomic, strong) NSSlider *slider;
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSMenu *contextMenu;

@end

@implementation DuskController

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  self.statusItem = [[NSStatusBar systemStatusBar]
      statusItemWithLength:NSVariableStatusItemLength];

  object_setClass(self.statusItem.button, [DuskStatusButton class]);

  DuskStatusButton *button = (DuskStatusButton *)self.statusItem.button;

  button.image = [NSImage imageWithSystemSymbolName:@"moon.fill"
                           accessibilityDescription:@"dusk"];

  [button setTarget:self];
  [button setAction:@selector(togglePopover:)];

  [self createContextMenu];

  objc_setAssociatedObject(button, DuskContextMenuKey, self.contextMenu,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  [self createPopover];
  [self createOverlay];
  [self updateOverlay];
}

- (void)createContextMenu {
  self.contextMenu = [[NSMenu alloc] init];

  NSMenuItem *aboutItem =
      [[NSMenuItem alloc] initWithTitle:@"About dusk"
                                 action:@selector(showAbout:)
                          keyEquivalent:@""];

  aboutItem.target = self;

  NSMenuItem *launchAtLoginItem =
      [[NSMenuItem alloc] initWithTitle:@"Launch at Login "
                                 action:@selector(toggleLaunchAtLogin:)
                          keyEquivalent:@""];

  launchAtLoginItem.state =
      [SMAppService mainAppService].status == SMAppServiceStatusEnabled
          ? NSControlStateValueOn
          : NSControlStateValueOff;

  NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit dusk"
                                                    action:@selector(quit:)
                                             keyEquivalent:@""];

  quitItem.target = self;

  [self.contextMenu addItem:aboutItem];
  [self.contextMenu addItem:[NSMenuItem separatorItem]];
  [self.contextMenu addItem:launchAtLoginItem];
  [self.contextMenu addItem:quitItem];
}

- (void)createPopover {
  NSViewController *viewController = [[NSViewController alloc] init];

  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 250, 60)];

  NSImageView *moon =
      [[NSImageView alloc] initWithFrame:NSMakeRect(10, 21, 18, 18)];

  moon.image = [NSImage imageWithSystemSymbolName:@"moon.fill"
                         accessibilityDescription:@"Darker"];

  moon.contentTintColor = [NSColor secondaryLabelColor];

  [view addSubview:moon];

  self.slider = [[NSSlider alloc] initWithFrame:NSMakeRect(35, 18, 180, 24)];

  self.slider.minValue = 0.0;
  self.slider.maxValue = 0.5;
  self.slider.doubleValue = 0.5;
  self.slider.continuous = YES;

  [self.slider setTarget:self];
  [self.slider setAction:@selector(sliderChanged:)];

  [view addSubview:self.slider];

  NSImageView *sun =
      [[NSImageView alloc] initWithFrame:NSMakeRect(222, 21, 18, 18)];

  sun.image = [NSImage imageWithSystemSymbolName:@"sun.max.fill"
                        accessibilityDescription:@"Brighter"];

  sun.contentTintColor = [NSColor secondaryLabelColor];

  [view addSubview:sun];

  viewController.view = view;

  self.popover = [[NSPopover alloc] init];

  self.popover.contentViewController = viewController;

  self.popover.behavior = NSPopoverBehaviorTransient;

  self.popover.contentSize = NSMakeSize(250, 60);

  self.popover.animates = YES;
}

- (void)createOverlay {
  NSScreen *screen = [NSScreen mainScreen];

  self.overlay =
      [[NSWindow alloc] initWithContentRect:screen.frame
                                  styleMask:NSWindowStyleMaskBorderless
                                    backing:NSBackingStoreBuffered
                                      defer:NO];

  self.overlay.backgroundColor = [NSColor blackColor];

  self.overlay.opaque = NO;
  self.overlay.ignoresMouseEvents = YES;

  self.overlay.level = NSScreenSaverWindowLevel;

  self.overlay.collectionBehavior =
      NSWindowCollectionBehaviorCanJoinAllSpaces |
      NSWindowCollectionBehaviorFullScreenAuxiliary |
      NSWindowCollectionBehaviorStationary;

  [self.overlay orderFrontRegardless];
}

- (void)updateOverlay {
  double amount = self.slider.maxValue - self.slider.doubleValue;

  self.overlay.alphaValue = amount;
}

- (void)sliderChanged:(NSSlider *)sender {
  [self updateOverlay];
}

- (void)togglePopover:(id)sender {
  if (self.popover.isShown) {
    [self.popover close];
    return;
  }

  [self.popover showRelativeToRect:self.statusItem.button.bounds
                            ofView:self.statusItem.button
                     preferredEdge:NSRectEdgeMinY];
}

- (void)showAbout:(id)sender {
  [NSApp orderFrontStandardAboutPanel:nil];
}

- (void)toggleLaunchAtLogin:(NSMenuItem *)sender {
  SMAppService *service = [SMAppService mainAppService];
  NSError *err = nil;

  if (service.status == SMAppServiceStatusEnabled) {
    [service unregisterAndReturnError:&err];
  } else {
    [service registerAndReturnError:&err];
  }

  if (err) {
    NSLog(@"Launch at Login error %@", err);
    return;
  }

  sender.state = service.status == SMAppServiceStatusEnabled
                     ? NSControlStateValueOn
                     : NSControlStateValueOff;
}

- (void)quit:(id)sender {
  [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  [self.overlay orderOut:nil];
}

@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];

    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];

    DuskController *controller = [[DuskController alloc] init];

    [app setDelegate:controller];

    [app run];
  }

  return EXIT_SUCCESS;
}
