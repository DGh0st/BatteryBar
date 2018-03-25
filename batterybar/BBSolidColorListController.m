#include "BBSolidColorListController.h"

@implementation BBSolidColorListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SolidColor" target:self] retain];
	}
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[self clearCache];
	[self reload];
	[super viewWillAppear:animated];
}

@end