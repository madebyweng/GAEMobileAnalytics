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


#define BaseURL			@"http://localhost:8083/log"
#define BaseEventsURL	@"http://localhost:8083/log/event"


#import <Foundation/Foundation.h>


@interface GAEMobileAnalytics : NSObject {
	NSString *apiKey, *secretKey;
	int startTime;
	NSString *basicAnalyticsRecordUrl, *eventsAnalyticsRecordUrl;
}

+ (GAEMobileAnalytics *)defaultLogger;

@property (nonatomic, retain) NSString *apiKey, *secretKey;
@property (nonatomic, retain) NSString *basicAnalyticsRecordUrl, *eventsAnalyticsRecordUrl;

- (id)initWithApiKey:(NSString*)_apiKey;
- (id)initWithApiKey:(NSString*)_apiKey baseUrl:(NSString*)basicUrl eventsUrl:(NSString*)eventsUrl;
- (void)logEvent:(NSString*)eventName parameters:(NSMutableDictionary*)parameters discreet:(BOOL)discreet;

@end
