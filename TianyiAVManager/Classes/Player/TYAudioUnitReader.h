//
//  TYAudioUnitReader.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioUnitReader : NSObject
///从已有的数据中读取数据
- (int)readDataFrom:(NSData *)dataStore len:(int)len forData:(Byte *)data;
@end

NS_ASSUME_NONNULL_END
