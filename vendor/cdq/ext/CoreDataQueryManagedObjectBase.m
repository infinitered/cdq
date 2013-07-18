#import "CoreDataQueryManagedObjectBase.h"
#import <objc/runtime.h>

@implementation CoreDataQueryManagedObjectBase

- (id)relationshipByName:(NSString *)name;
{
  // should be overriden by the subclass
  printf("Unimplemented\n");
  abort();
  return nil;
}

+ (void)defineRelationshipMethod:(NSString *)name;
{
  IMP imp = imp_implementationWithBlock(^id(CoreDataQueryManagedObjectBase *entity) {
    return [entity relationshipByName:name];
  });
  class_addMethod([self class], NSSelectorFromString(name), imp, "@@:");
}

@end
