//
//  QCloudOfflineAuthInfo.h
//  QCloudTTS
//
//  Created by dgw on 2022/6/15.
//

#import <Foundation/Foundation.h>
/*如果您下载的是在线版TTS SDK ,请忽略此接口文件*/
NS_ASSUME_NONNULL_BEGIN

// 离线授权错误吗
typedef NS_ENUM(NSInteger, AuthErrorCode) {
    OFFLINE_AUTH_SUCCESS = 0,//"Auth Success"
    
    OFFLINE_AUTH_NETWORK_CONNECT_FAILED = -10,//"Network connect failed."
    OFFLINE_AUTH_NETWORK_SERVER_AUTH_FAILED = -11,//"Server Authorization Error ！See Response Message."

    OFFLINE_AUTH_PARAMETERS_ERROR = -12,//"Parameter cannot be empty."
    OFFLINE_AUTH_PACKAGENAME_ERROR = -13,//"Authorization package name error."
    OFFLINE_AUTH_DEVICE_ID_ERROR = -14,//"Authorization device ID error."
    OFFLINE_AUTH_GET_DEVICE_ID_FAILED = -15,//"The device is abnormal and the device ID cannot be obtained."
    OFFLINE_AUTH_PLATFORM_ERROR = -16,//"The platform is not authorized."
    OFFLINE_AUTH_BIZCODE_ERROR = -17,//"License business does not match."
    OFFLINE_AUTH_EXPIRED = -18,//"Authorization has expired.")
    OFFLINE_AUTH_JSON_PARSE_FAILED = -19,//"JSON Parsing Error."
    OFFLINE_AUTH_DECODE_ERROR = -20,//"Could not decode license, please check input parameters."
    OFFLINE_AUTH_UNKNOWN_ERROR = -21,//"Unknown authorization error."

};
// 离线授权信息类
@interface QCloudOfflineAuthInfo : NSObject

@property (nonatomic, copy, nullable) NSString*  respose; //使用在线拉取授权时，服务器返回到json数据

@property (nonatomic, assign) AuthErrorCode err_code; //错误码
@property (nonatomic, copy, nullable) NSString*  err_msg; //错误信息

@property (nonatomic, copy, nullable) NSString*  deviceId; //设备id
@property (nonatomic, copy, nullable) NSString*  expireTime; //到期时间
@property (nonatomic, copy, nullable) NSString*  voiceAuthList; //已授权的音色名列表，用分号隔开

+(instancetype _Nonnull )getQCloudOfflineAuthInfo:(AuthErrorCode)err_code Respose:(NSString*_Nullable)respose;

+(NSString* _Nonnull )getErrorMsg:(AuthErrorCode)code;
@end

NS_ASSUME_NONNULL_END
