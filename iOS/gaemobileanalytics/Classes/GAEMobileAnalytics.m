/**
 * Copyright (c) 2010 Muh Hon Cheng
 * Created by honcheng on 12/16/10.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining 
 * a copy of this software and associated documentation files (the 
 * "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, 
 * distribute, sublicense, and/or sell copies of the Software, and to 
 * permit persons to whom the Software is furnished to do so, subject 
 * to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be 
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT 
 * WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR 
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT 
 * SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
 * IN CONNECTION WITH THE SOFTWARE OR 
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * @author 		Muh Hon Cheng <honcheng@gmail.com>
 * @copyright	2010	Muh Hon Cheng
 * @version
 * 
 */

#import "GAEMobileAnalytics.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "SBJSON.h"


#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/mach.h>



@interface GAEMobileAnalytics()
- (void)postToUrl:(NSString*)baseUrl parameters:(NSMutableDictionary*)parameters;
- (NSString*)getSHA256Hash:(NSString*)input;
@end

@implementation GAEMobileAnalytics
@synthesize apiKey, secretKey, basicAnalyticsRecordURL, eventsAnalyticsRecordURL;
@synthesize runDebug;

static GAEMobileAnalytics *defaultLogger = nil;


/*!
 @method getGlobalDeviceId
 @abstract A unique device identifier is a hash value composed from various hardware identifiers such
 as the device’s serial number. It is guaranteed to be unique for every device but cannot 
 be tied to a user account. [UIDevice Class Reference]
 @return An 1-way hashed identifier unique to this device.
 */
- (NSString *)getGlobalDeviceId {
	NSString *systemId = [[UIDevice currentDevice] uniqueIdentifier];
	if (systemId == nil) {
		return nil;
	}
	return systemId;
}

/*!
 @method getTimeAsDatetime
 @abstract Gets the current time, along with local timezone, formatted as a DateTime for the webservice. 
 @return a DateTime of the current local time and timezone.
 */
- (NSString *)getTimeAsDatetime {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss-00:00"];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	return [dateFormatter stringFromDate:[NSDate date]];
}

/*!
 @method isDeviceJailbroken
 @abstract checks for the existance of apt to determine whether the user is running any
 of the jailbroken app sources.
 @return whether or not the device is jailbroken.
 */
- (BOOL) isDeviceJailbroken {
	NSFileManager *sessionFileManager = [NSFileManager defaultManager];	
	return [sessionFileManager fileExistsAtPath:PATH_TO_APT];
}

/*!
 @method getDeviceModel
 @abstract Gets the device model string. 
 @return a platform string identifying the device
 */
- (NSString *)getDeviceModel {
	char *buffer[256] = { 0 };
	size_t size = sizeof(buffer);
    sysctlbyname("hw.machine", buffer, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:(const char*)buffer
											encoding:NSUTF8StringEncoding];
	return platform;
}

/*!
 @method modelSizeString
 @abstract Checks how much disk space is reported and uses that to determine the model
 @return A string identifying the model, e.g. 8GB, 16GB, etc
 */
- (NSString *)modelSizeString {
	
#if TARGET_IPHONE_SIMULATOR
	return @"SIMULATOR";
#endif
	
	// User partition
	NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *stats = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[path lastObject] error:nil];  
	uint64_t user = [[stats objectForKey:NSFileSystemSize] longLongValue];
	
	// System partition
	path = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES);
    stats = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[path lastObject] error:nil];  
	uint64_t system = [[stats objectForKey:NSFileSystemSize] longLongValue];
	
	// Add up and convert to gigabytes
	// TODO: seem to be missing a system partiton or two...
	NSInteger size = (user + system) >> 30;
	
	// Find nearest power of 2 (eg, 1,2,4,8,16,32,etc).  Over 64 and we return 0
	for (NSInteger gig = 1; gig < 257; gig = gig << 1) {
		if (size < gig)
			return [NSString stringWithFormat:@"%dGB", gig];
	}
	return nil;
}

/*!
 @method availableMemory
 @abstract Reports how much memory is available  
 @return A double containing the available free memory
 */
- (NSString*)availableMemory {
	unsigned long long available = NSNotFound;
	vm_statistics_data_t stats;
	mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
	if (!host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&stats, &count))
		available = vm_page_size * stats.free_count;
	
	//Kilobytes
	double result = available / 1024;
	
	if (result > 1024)
	{
		//Megabytes
		result = result / 1024;
		
		if (result > 1024)
		{
			//Gigabytes
			result = result / 1024;
			return [@"" stringByAppendingFormat:@"%3.1fGB", result];
		}
		return [@"" stringByAppendingFormat:@"%3.1fMB", result];
	}
	
	return [@"" stringByAppendingFormat:@"%3.1fKB", result];
}

+ (GAEMobileAnalytics *)defaultLogger
{
	@synchronized(self)
	{
		if (defaultLogger==nil)
		{
			[[self alloc] init];
		}
	}
	return defaultLogger;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
		if (defaultLogger==nil)
		{
			defaultLogger = [super allocWithZone:zone];
			return defaultLogger;
		}
	}
	return nil;
}

- (id)copyWithZone:(NSZone *)zone 
{
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount 
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release 
{
    //do nothing
}

- (id)autorelease 
{
    return self;
}

- (void)dealloc {
	[apiKey release];
	[secretKey release];
	[basicAnalyticsRecordURL release];
	[eventsAnalyticsRecordURL release];
	[super dealloc];
}

- (id)initWithApiKey:(NSString*)_apiKey 
{
	if (self = [super init]) 
	{
		[self initWithApiKey:_apiKey baseUrl:nil eventsUrl:nil];
	}
	return self;
}

- (id)initWithApiKey:(NSString*)_apiKey baseUrl:(NSString*)baseUrl eventsUrl:(NSString*)eventsUrl
{
	if (self = [super init]) 
	{
		self.apiKey = _apiKey;
		self.basicAnalyticsRecordURL = baseUrl;
		self.eventsAnalyticsRecordURL = eventsUrl;
		self.runDebug = NO;
		
		if (baseUrl == nil)
			self.basicAnalyticsRecordURL = GAEMA_BaseURL;
		
		if (eventsUrl == nil)
			self.eventsAnalyticsRecordURL = GAEMA_BaseEventsURL;
		
		[self postToUrl:self.basicAnalyticsRecordURL parameters:nil];
	}
	return self;
}

- (void)logEvent:(NSString*)eventName parameters:(NSMutableDictionary*)parameters discreet:(BOOL)discreet
{
	NSMutableDictionary *post_parameters = [NSMutableDictionary dictionary];
	[post_parameters setObject:[NSNumber numberWithBool:discreet] forKey:@"is_discreet"];
	[post_parameters setObject:eventName forKey:@"event"];
	
	if (parameters)
	{
		SBJSON *jsonParser = [SBJSON new];
		NSString *jsonString = [jsonParser stringWithObject:parameters];
		[jsonParser release];
		
		[post_parameters setObject:jsonString forKey:@"parameters"];
	}
	[self postToUrl:self.eventsAnalyticsRecordURL parameters:post_parameters];
}

- (void)postToUrl:(NSString*)baseUrl parameters:(NSMutableDictionary*)parameters
{
	if (startTime==0)
	{
		startTime = [[NSDate date] timeIntervalSince1970];
		NSString *seed = [NSString stringWithFormat:@"%@%i", self.apiKey, startTime];
		self.secretKey = [self getSHA256Hash:seed];
	}
	
	if (!parameters)
	{
		parameters = [NSMutableDictionary dictionary];
	}
	
	UIDevice *device = [UIDevice currentDevice];
	NSLocale *locale = [NSLocale currentLocale];
	NSLocale *english = [[[NSLocale alloc] initWithLocaleIdentifier: @"en_US"] autorelease];
	NSLocale *device_locale = [[NSLocale preferredLanguages] objectAtIndex:0];	
    NSString *device_language = [english displayNameForKey:NSLocaleIdentifier value:device_locale];
	NSString *locale_country = [english displayNameForKey:NSLocaleCountryCode value:[locale objectForKey:NSLocaleCountryCode]];		
	
	
	[parameters setObject:[NSNumber numberWithInt:startTime] forKey:@"t"];
	[parameters setObject:self.secretKey forKey:@"s"];

	// Device
	[parameters setObject:[NSString stringWithFormat:@"%d",[[NSNumber numberWithBool:[self isDeviceJailbroken]] intValue]] forKey:@"device_jb"];
#if TARGET_IPHONE_SIMULATOR	
	[parameters setObject:@"SIMULATOR" forKey:@"os"];
#else
	[parameters setObject:[device systemName] forKey:@"os"];
#endif
	[parameters setObject:[device systemVersion] forKey:@"os_ver"];
	
	[parameters setObject:[device uniqueIdentifier] forKey:@"device_id"];
	[parameters setObject:device_language forKey:@"device_language"];
	[parameters setObject:locale_country forKey:@"locale_country"];
	[parameters setObject:[locale objectForKey:NSLocaleCountryCode] forKey:@"device_country"];
	[parameters setObject:[self getDeviceModel] forKey:@"device_model"];
	[parameters setObject:[self availableMemory] forKey:@"device_memory"];
	[parameters setObject:[self modelSizeString] forKey:@"device_size"];
	[parameters setObject:@"Apple" forKey:@"manufacturer"];
	
	CTTelephonyNetworkInfo *telephony = [[[CTTelephonyNetworkInfo alloc] init] autorelease];
	CTCarrier *carrier = [telephony subscriberCellularProvider];
	
	NSString *carrierName = [carrier carrierName];
	if (carrierName==nil) carrierName = @"No Carrier";
	carrierName = [carrierName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	[parameters setObject:carrierName forKey:@"telco"];
	
	// App
	[parameters setObject:GAEMA_APP_ID forKey:@"app_id"];
	[parameters setObject:GAEMA_APP_VER forKey:@"app_ver"];
	[parameters setObject:GAEMA_APP_NAME forKey:@"app_name"];

	if (self.runDebug) {
		NSLog(@"parameter = %@", parameters);
		//	NSHost* myhost =[NSHost currentHost];
		//	NSString *ad = [myhost address];
		//	NSLog(@"address = %@", ad);
	}

	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:baseUrl]
																 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
															 timeoutInterval:60] autorelease];
	[request setHTTPMethod:@"POST"];
	
	NSMutableString *parameterString = [NSMutableString stringWithString:@""];
	int i;
	for (i=0; i<[[parameters allKeys] count]; i++)
	{
		NSString *key = [[parameters allKeys] objectAtIndex:i];
		id value = [parameters objectForKey:key];
		if (i!=0) [parameterString appendString:@"&"];
		[parameterString appendFormat:@"%@=%@", key, value];
	}
	
	NSData *postData = [parameterString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];
	
	[[NSURLConnection alloc] initWithRequest:request delegate:nil];
}

- (NSString*)getSHA256Hash:(NSString*)input
{
	const char *cStr = [input UTF8String];
	unsigned char result[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(cStr, strlen(cStr), result);
	
	NSString *sha256Key = [NSString 
						stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
						result[0], result[1],
						result[2], result[3],
						result[4], result[5],
						result[6], result[7],
						result[8], result[9],
						result[10], result[11],
						result[12], result[13],
						result[14], result[15],
						result[16], result[17],
						result[18], result[19],
						result[20], result[21],
						result[22], result[23],
						result[24], result[25],
						result[26], result[27],
						result[28], result[29],
						result[30], result[31]
						];
	return sha256Key;
}

@end
