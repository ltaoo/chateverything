//
//  QCloudTTSEngine.h
//  cloud-tts-sdk-ios
//
//  Created by dgw on 2022/1/10.
//

#import <Foundation/Foundation.h>
#import <QCloudTTS/TtsError.h>
#import <QCloudTTS/QCloudOfflineAuthInfo.h>


typedef NS_ENUM(NSUInteger, TtsMode) {
    TTS_MODE_ONLINE = 0, //在线模式
    TTS_MODE_OFFLINE = 1, //离线模式
    TTS_MODE_MIX = 2   //离在线混合模式
};



/// 回调接口
@protocol QCloudTTSEngineDelegate <NSObject>

@optional
/// 合成结果回调
/// @param data 音频数据
/// @param utteranceId  utteranceId
/// @param text  text
/// @param type 该句话是以何种引擎生成的：0:在线 1:离线
/// @deprecated
-(void) onSynthesizeData:(NSData *_Nullable)data UtteranceId:(NSString *_Nullable)utteranceId Text:(NSString *_Nullable)text EngineType:(NSInteger)type;

/// 合成结果回调
/// @param data 音频数据
/// @param utteranceId  utteranceId
/// @param text  text
/// @param type 该句话是以何种引擎生成的：0:在线 1:离线
/// @param requestId 请求ID，仅engineType为0时不为nil，用于排查问题
-(void) onSynthesizeData:(NSData *_Nullable)data UtteranceId:(NSString *_Nullable)utteranceId Text:(NSString *_Nullable)text EngineType:(NSInteger)type RequestId:(NSString* _Nullable)requestId;

/// 合成结果回调
/// @param data 音频数据
/// @param utteranceId  utteranceId
/// @param text  text
/// @param type 该句话是以何种引擎生成的：0:在线 1:离线
/// @param respJson 请求结果
-(void) onSynthesizeData:(NSData *_Nullable)data UtteranceId:(NSString *_Nullable)utteranceId Text:(NSString *_Nullable)text EngineType:(NSInteger)type RequestId:(NSString* _Nullable)requestId RespJson:(NSString* _Nullable)respJson;

@required
/// 错误回调
/// @param error 错误信息
/// @param utteranceId utteranceId
/// @param text text
-(void) onError:(TtsError *_Nullable)error UtteranceId:(NSString *_Nullable)utteranceId Text:(NSString *_Nullable)text;


/// 返回离线合成模块授权信息，使用混合或者离线模式时，收到此方法成功回调后才可以调用合成接口
/// 如果您下载的是在线版TTS SDK ,或者只使用在线合成模式,请忽略此方法
/// @param OfflineAuthInfo 授权信息，当OfflineAuthInfo.err_msg为0时授权成功，详见QCloudOfflineAuthInfo.h
-(void) onOfflineAuthInfo:(QCloudOfflineAuthInfo* _Nonnull )OfflineAuthInfo;

@end



/// 语音合成引擎接口
@interface QCloudTTSEngine : NSObject


/// 获得QCloudTTSEngine实例
+(id _Nullable )getShareInstance;

/// 销毁QCloudTTSEngine实例
+(void) instanceRelease;


/// 初始化引擎
/// @param mode 引擎模式，在线、离线、混合，如切换引擎，需要先执行instanceRelease
/// @param delegate 用于接收结果的代理
-(void) engineInit:(TtsMode)mode Delegate:(id<QCloudTTSEngineDelegate> _Nonnull) delegate;


/// 取消合成，清空内部合成队列
-(TtsError *_Nullable) cancel;

/// 合成接口，支持持续调用添加文本
/// @param text 需要合成的文本
/// @param utteranceId  用于标记文本的id，合成完成后随音频文件或者错误接口返回,可为空
-(TtsError *_Nullable) synthesize:(NSString *_Nonnull)text UtteranceId:(NSString *_Nullable)utteranceId;





/// 配置在线引擎鉴权参数
/// @param appId   appId
/// @param secretId  secretId
/// @param secretKey  secretKey
/// @param token  token，可为空，如果使用sts临时证书鉴权，secretId和secretKey均入参临时的，同时需要入参对应的token，
/// sts临时证书具体详见https://cloud.tencent.com/document/product/598/33416 （开发调试时建议先用普通方式鉴权，token填nil）
-(void) setOnlineAuthParam:(NSInteger)appId SecretId:(NSString* _Nonnull)secretId SecretKey:(NSString* _Nonnull)secretKey Token:(NSString* _Nullable)token;



///online语音相关设置

/// 设置在线语速,对setOnlineParam的封装
/// @param voiceSpeed 默认0，代表正常速度
-(void)setOnlineVoiceSpeed:(float)voiceSpeed;

/// 设置在线音色ID,对setOnlineParam的封装
/// @param voiceType 默认1001，音色id可查看官网文档https://cloud.tencent.com/document/product/1073/37995
-(void)setOnlineVoiceType:(int)voiceType;

/// 设置在线引擎音量,对setOnlineParam的封装
/// @param voiceVolume   默认0，代表正常音量，没有静音选项
-(void)setOnlineVoiceVolume:(float)voiceVolume;

/// 设置主语言类型,对setOnlineParam的封装
/// @param primaryLanguage  1:中文 2:英文 默认1
-(void)setOnlineVoiceLanguage:(int)primaryLanguage;

///在线编码格式，如无业务特殊需求不建议更改（默认"mp3",目前支持"mp3","wav","pcm",若更改为pcm不支持直接播放,对setOnlineParam的封装
-(void)setOnlineCodec:(NSString* _Nonnull) code;

/// 项目ID
/// @param projectId  默认0, 对setOnlineParam的封装
-(void)setOnlineProjectId:(int)projectId;

/// 是否开启时间戳功能，默认为false,对setOnlineParam的封装
- (void)setOnlineEnableSubtitle:(Boolean)val;

/// 断句敏感阈值，默认值为：0,对setOnlineParam的封装
- (void)setOnlineSegmentRate:(int)val;

/// 控制合成音频的情感，仅支持多情感音色使用,对setOnlineParam的封装
- (void)setOnlineEmotionCategory:(NSString* _Nullable)val;

/// 控制合成音频情感程度,对setOnlineParam的封装
- (void)setOnlineEmotionIntensity:(int)val;

/// 设置自定义参数,可使用该方法控制请求时的参数
/// @param value为nil时将删除参数,否则会在请求中添加参数
- (void)setOnlineParam:(NSString* _Nonnull)key value:(NSObject* _Nullable)value;

/// 设置区域
/// @param region 默认为ap-shanghai,无特殊需求请勿更改
- (void)setOnlineRegion:(NSString *)region;

//设置是否输出日志
-(void)setEnableDebugLog:(BOOL)enableDebugLog;




/// timeoutIntervalForRequest ,0.5s - 30s 默认15000ms(15s)
/// @param timeout [2200,60000] 单位ms
- (void)setTimeoutIntervalForRequest:(int)timeout;


/// timeoutIntervalForResource  2.2s - 60s  默认30000ms(30s)
/// @param timeout   [500,30000] 单位ms
-(void)setTimeoutIntervalForResource:(int) timeout;


/// Mix模式下，出现网络错误后的检测间隔时间, 默认值5分钟
///注意：每次检测时将使用所入参的一句文本请求服务器，如果后端合成成功将会额外消耗该句字数的合成额度
/// @param checkNetworkIntervalTime 大于等于0 单位s, 等于0时持续检测，直到成功
-(void)setCheckNetworkIntervalTime:(int) checkNetworkIntervalTime;


//以下为离线语音相关参数配置

//resourceDir 离线资源路径
-(void)setOfflineResourceDir:(NSString * _Nonnull) resourceDir;

//voiceSpeed [0.5,2.0]
-(void)setOfflineVoiceSpeed:(float) voiceSpeed;

//voiceType 离线音色名称，名称配置位于音色资源目录\voices\config.json 中，可自行指定更多的音色，demo中仅提供"pb"、"femalen"两种
-(void)setOfflineVoiceType:(NSString *_Nonnull)  voiceType;

//voiceVolume >0
-(void)setOfflineVoiceVolume:(float) voiceVolume;

/// 配置离线TTS授权参数: 在线下载密钥（第一次激活设备需要联网）
/// @param licPk 密钥对应的licPk,请在腾讯云官网页面获取，或者由腾讯云商务线下下发
/// @param licKey 密钥对应的licKey,请在腾讯云官网页面获取，或者由腾讯云商务线下下发
/// @param secretId  腾讯云secretId （可能与在线模式不是同一个账号，需要输入购买离线SDK对应的账号的secretId）
/// @param secretKey 腾讯云 secretKey（可能与在线模式不是同一个账号，需要输入购买离线SDK对应的账号的secretKey）
/// @param token token，可为空，如果使用sts临时证书鉴权，secretId和secretKey均入参临时的，同时需要入参对应的token，
-(void)setOfflineAuthParamDoOnline:(NSString* _Nonnull)licPk
                                    LicKey:(NSString* _Nonnull)licKey
                                    SecretId:(NSString* _Nonnull)secretId
                                    SecretKey:(NSString* _Nonnull)secretKey
                                    Token:(NSString* _Nullable)token;

/// 配置离线TTS授权参数: 在线下载密钥（第一次激活设备需要联网）
/// @param licPk 密钥对应的licPk,请在腾讯云官网页面获取，或者由腾讯云商务线下下发
/// @param licKey 密钥对应的licKey,请在腾讯云官网页面获取，或者由腾讯云商务线下下发
/// @param secretId  腾讯云secretId （可能与在线模式不是同一个账号，需要输入购买离线SDK对应的账号的secretId）
/// @param secretKey 腾讯云 secretKey（可能与在线模式不是同一个账号，需要输入购买离线SDK对应的账号的secretKey）
/// @param token token，可为空，如果使用sts临时证书鉴权，secretId和secretKey均入参临时的，同时需要入参对应的token，
/// @param refreshAuth  是否强制联网刷新授权(NO:仅第一次联网激活下载授权文件; YES:联网刷新授权文件，无网络下将激活失败)
-(void)setOfflineAuthParamDoOnline:(NSString* _Nonnull)licPk
                                    LicKey:(NSString* _Nonnull)licKey
                                    SecretId:(NSString* _Nonnull)secretId
                                    SecretKey:(NSString* _Nonnull)secretKey
                                    Token:(NSString* _Nullable)token
                                    RefreshAuth:(BOOL)refreshAuth;


/// 配置离线TTS授权参数: 直接传入密钥（第一次激活也不需要联网）
/// @param lic 授权密钥 ，请在腾讯云官网页面获取，或者由腾讯云商务线下下发
/// @param licPk 该密钥对应的licPk，请在腾讯云官网页面获取，或者由腾讯云商务线下下发
/// @param licSign 该密钥对应的licSign，请在腾讯云官网页面获取，或者由腾讯云商务线下下发
-(void)setOfflineAuthParamDoOffline:(NSString* _Nonnull)lic
                              LicPk:(NSString* _Nonnull)licPk
                            LicSign:(NSString* _Nonnull)licSign;
@end


