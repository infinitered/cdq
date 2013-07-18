#import <CoreData/CoreData.h>

@interface CoreDataQueryManagedObjectBase : NSManagedObject

- (id)relationshipByName:(NSString *)name;
+ (void)defineRelationshipMethod:(NSString *)name;

@end
