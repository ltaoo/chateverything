#import <Foundation/Foundation.h>
#import <QCloudTTS/QCPlayerError.h>

@protocol QCloudPlayerDelegate <NSObject>
//播放开始
-(void) onTTSPlayStart;

//队列所有音频播放完成，音频等待中
-(void) onTTSPlayWait;

//恢复播放
-(void) onTTSPlayResume;

//暂停播放
-(void) onTTSPlayPause;

//播放中止
-(void)onTTSPlayStop;

//即将播放播放下一句，即将播放音频对应的句子，以及这句话utteranceId
/// 即将播放播放下一句，即将播放音频对应的句子，以及这句话utteranceId
/// @param text 当前播放句子的文本
/// @param utteranceId 当前播放音频对应的ID
-(void) onTTSPlayNextWithText:(NSString* _Nullable)text UtteranceId:(NSString* _Nullable)utteranceId;



//播放器异常
-(void)onTTSPlayError:(QCPlayerError* _Nullable)playError;

/// 当前播放的字符,当前播放的字符在所在的句子中的下标.
/// @param currentWord 当前读到的单个字，是一个估算值不一定准确
/// @param currentIdex 当前播放句子中读到文字的下标
-(void)onTTSPlayProgressWithCurrentWord:(NSString*_Nullable)currentWord CurrentIndex:(NSInteger)currentIdex;


@end
