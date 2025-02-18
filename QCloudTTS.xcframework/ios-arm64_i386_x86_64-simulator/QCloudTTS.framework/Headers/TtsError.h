//
//  TtsError.h
//  cloud-tts-sdk-ios
//
//  Created by dgw on 2022/1/10.
//

#ifndef TtsError_h
#define TtsError_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TtsErrorCode) {
    
    TTS_ERROR_CODE_UNINITIALIZED = -100, //Engine uninitialized
    TTS_ERROR_CODE_GENERATE_SIGN_FAIL = -101, //generate sign failed
    TTS_ERROR_CODE_NETWORK_CONNECT_FAILED = 102, //network connect failed
    TTS_ERROR_CODE_DECODE_FAIL = -103, //JSON Response Parsing Error
    TTS_ERROR_CODE_SERVER_RESPONSE_ERROR = -104, //Server response error
    TTS_ERROR_CODE_CANCEL_FAILURE = -106, //Cancel failure，please try again later
    
    TTS_ERROR_CODE_OFFLINE_FAILURE = -107,//Offline synthesize failed, please check your text and VoiceType
    TTS_ERROR_CODE_OFFLINE_INIT_FAILURE = -108,//Offline engine initialization failed, please check resource files
    TTS_ERROR_CODE_OFFLINE_AUTH_FAILURE = -109,//Offline engine auth failure
    TTS_ERROR_CODE_OFFLINE_TEXT_TOO_LONG = -110, //Offline synthesize failed,text too long,MAX <= 1024 byte
    TTS_ERROR_CODE_OFFLINE_VOICE_AUTH_FAILURE = -111, //This voice not authorized, please change it
    
    TTS_ERROR_CODE_OFFLINE_NOSUPPORT = -900 //This SDK only supports online mode
};
    





/// 后端返回的错误信息
@interface TtsServiceError : NSObject

@property (nonatomic, copy) NSString*  _Nullable err_code;
@property (nonatomic, copy) NSString*  _Nullable msg;
@property (nonatomic, copy) NSString*  _Nullable respose;

+(instancetype _Nonnull)getTtsServiceError:(NSString *_Nullable)err_code ErrorMsg:(NSString*  _Nullable)msg Respose:(NSString*  _Nullable)respose;

@end


/// 错误信息类
@interface TtsError : NSObject

@property (nonatomic, assign) TtsErrorCode err_code; //错误码

@property (nonatomic, copy, nullable) NSString*  msg; //错误信息

@property (nonatomic, copy, nullable) NSError *  error; //系统抛出的错误信息（不一定有，可能为空）

@property (nonatomic, strong ,nullable) TtsServiceError *  serviceError;//服务器返回的错误信息（不一定有，可能为空）

+(instancetype _Nonnull)getTtsError:(TtsErrorCode)err_code
                        TtsServiceError:(TtsServiceError* _Nullable)serviceError
                        NSErrorMsg:(NSError *_Nullable)error;
@end







#endif /* TtsError_h */
