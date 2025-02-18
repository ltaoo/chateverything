//
//  QCloudRealTTSController.h
//  QCloudRealTTS
//
//  Created by tbolp on 2024/11/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString* const kRealText;
FOUNDATION_EXPORT NSString* const kRealVoiceType;
FOUNDATION_EXPORT NSString* const kRealVolume;
FOUNDATION_EXPORT NSString* const kRealSpeed;
FOUNDATION_EXPORT NSString* const kRealSampleRate;
FOUNDATION_EXPORT NSString* const kRealCodec;
FOUNDATION_EXPORT NSString* const kRealEnableSubtitle;
FOUNDATION_EXPORT NSString* const kRealEmotionCategory;
FOUNDATION_EXPORT NSString* const kRealEmotionIntensity;
FOUNDATION_EXPORT NSString* const kRealSegmentRate;
FOUNDATION_EXPORT NSString* const kRealFastVoiceType;

enum : NSInteger {
    REALTTSPARAMETERERROR = 2000, // 参数错误,SDK配置项设置有问题,一般为授权信息没有设置
    REALTTSWEBSOCKETERROR = 2001, // websocket错误,网络问题
    REALTTSCANCELERROR = 2002, // 取消错误,成功调用cancel返回此错误
    REALTTSSERVERERROR = 2003, // 服务端返回错误,可通过取userInfo中的Message获取详细信息
};

@protocol QCloudRealTTSController <NSObject>
/*
 * 取消合成任务
 */
-(void)cancel;

@end

@protocol QCloudRealTTSListener <NSObject>

/*
 * 合成任务结束
 */
-(void)onFinish;
/*
 * 合成任务出错
 * @param error 错误信息
 */
-(void)onError:(nonnull NSError*)error;

@optional
/*
 * 合成日志
 * @param value 日志信息
 * @param level 日志等级
 */
-(void)onLog:(nonnull NSString*)value level:(int)level;
/*
 * 服务端返回的音频数据,可参考文档https://cloud.tencent.com/document/product/1073/94308 说明
 * @param data 服务端返回的音频数据
 */
-(void)onData:(nonnull NSData*)data;
/*
 * 服务端返回的json数据,可参考文档https://cloud.tencent.com/document/product/1073/94308 说明
 * @param msg 服务端返回的json数据
 */
-(void)onMessage:(nonnull NSString*)msg;

@end

@interface QCloudRealTTSConfig : NSObject

@property (nonnull) NSString* appID; // 腾讯云 appid
@property (nonnull) NSString* secretID; // 腾讯云 secretID
@property (nonnull) NSString* secretKey; // 腾讯云 secretKey
@property (nonnull) NSString* token;  // 临时token,不为空字符时生效,使用临时token时,secretId,secretKey需为临时密钥
@property int connectTimeout; // > 0 生效,单位为ms,默认为0

/*
 * 设置传入后台的api的参数,参数可参考文档https://cloud.tencent.com/document/product/1073/94308 说明
 * @param key 参数名称
 * @param value 参数值,参数值为nil会删除已设置的key
 */
- (QCloudRealTTSConfig*)setApiParam:(nonnull NSString*)key value:(nullable NSString*)value;
- (QCloudRealTTSConfig*)setApiParam:(nonnull NSString*)key ivalue:(NSInteger)value;
- (QCloudRealTTSConfig*)setApiParam:(nonnull NSString*)key fvalue:(float)value;
- (QCloudRealTTSConfig*)setApiParam:(nonnull NSString*)key bvalue:(BOOL)value;

/*
 * 创建实时语音合成控制器
 * @param listener 用于回调合成任务的接口及中间信息
 */
- (id<QCloudRealTTSController>)build:(id<QCloudRealTTSListener>)listener;
@end


NS_ASSUME_NONNULL_END
