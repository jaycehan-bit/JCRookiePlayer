//
//  JCPlayerAsynModuleDefine.h
//  JCImage
//
//  Created by jaycehan on 2024/3/14.
//

#import <Foundation/Foundation.h>

// 无效的流索引
FOUNDATION_EXTERN const NSInteger JCPlayerInvalidStreamIndex;


typedef NS_ENUM(NSUInteger, JCPlayerOpenFileStatus) {
    JCPlayerOpenFileStatusSuccess = 0,  // 打开成功
    JCPlayerOpenFileStatusFailed = 1,   // 打开失败
};

typedef NS_ENUM(NSInteger, JCDecodeErrorCode) {
    JCDecodeErrorCodeSuccess = 0,           // 成功
    JCDecodeErrorCodeInvalidPath = 1,       // 错误路径
    JCDecodeErrorCodeInvalidFile = 2,       // 无效视频文件
    JCDecodeErrorCodeInvalidStream = 3,     // 无效视频流
    JCDecodeErrorCodecContextError = 4,     // 解码器上下文错误
    JCDecodeErrorCodecOpenCodecError = 5,   // 打开解码器错误
    
    
    JCDecodeErrorCodeEAGAIN = 101,           // 解码帧失败，需继续send pakcet
    JCDecodeErrorCodeReadError = 102,        // read packet失败
    JCDecodeErrorCodeSendPacket = 103,       // send pakcet失败
    JCDecodeErrorCodeReceiveFrame = 104,     // receive frame失败
    JCDecodeErrorCodeEOF = 105,              // receive EOF
};
