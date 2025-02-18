//
//  QPlayerError.h
//  cloud-tts-sdk-ios
//
//  Created by renqiu on 2022/1/11.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger,QCPlayerErrorCode){
    
       QPLAYER_ERROR_CODE_EXCEPTION = -201,
       QPLAYER_ERROR_CODE_PLAY_QUEUE_IS_FULL = -202,
       QPLAYER_ERROR_CODE_AUDIO_READ_FAILEDL = -203,
       QPLAYER_ERROR_CODE_UNKNOW = -204,
    
};
@interface QCPlayerError : NSObject
@property (nonatomic, assign) NSInteger mCode;
@property (nonatomic,copy)NSString *message;
@property (nonatomic,strong)NSError *errorMessage;
+(instancetype)getQCPlayerErrorWithMcode:(NSInteger)mCode ErrorMessage:(NSError*)errorMessage;
@end


