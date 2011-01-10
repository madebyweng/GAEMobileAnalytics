

#define GAEMA_BaseURL		@"http://localhost:8083/log"
#define GAEMA_BaseEventsURL	@"http://localhost:8083/log/event"
#define GAEMA_BaseAPIKey	@"put-a-few-random-characters-here"


#define PATH_TO_APT			@"/private/var/lib/apt/"
#define GAEMA_APP_NAME		[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]
#define GAEMA_APP_VER		[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey]
#define GAEMA_APP_ID		[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleIdentifierKey]
