

#define GAEMA_BaseURL		@"http://localhost:8083/log"
#define GAEMA_BaseEventsURL	@"http://localhost:8083/log/event"
#define GAEMA_BaseAPIKey	@"put-a-few-random-characters-here"

/*
#define GAEMA_BaseURL		@"http://amobapp.appspot.com/log"
#define GAEMA_BaseEventsURL	@"http://amobapp.appspot.com/log/event"
#define GAEMA_BaseAPIKey	@"c1f3d06e219c0b2393ee88750bd99db9"
*/

#define PATH_TO_APT			@"/private/var/lib/apt/"
#define GAEMA_APP_NAME		[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]
#define GAEMA_APP_VER		[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey]
#define GAEMA_APP_ID		[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleIdentifierKey]
