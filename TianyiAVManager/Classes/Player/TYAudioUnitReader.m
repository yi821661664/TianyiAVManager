//
//  TYAudioUnitReader.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/17.
//

#import "TYAudioUnitReader.h"

@interface TYAudioUnitReader()

@property (nonatomic,assign) UInt32 readerLength;

@end

@implementation TYAudioUnitReader

- (int)readDataFrom:(NSData *)dataStore len:(int)len forData:(Byte *)data
{
    UInt32 currentReadLength = 0;
    if (_readerLength >= dataStore.length)
    {
        _readerLength = 0;
        return currentReadLength;
    }
    NSRange range;
    if (_readerLength+ len <= dataStore.length)
    {
        currentReadLength = len;
        range = NSMakeRange(_readerLength, currentReadLength);
        _readerLength = _readerLength + len;
    }
    else
    {
        currentReadLength = (UInt32)(dataStore.length - _readerLength);
        range = NSMakeRange(_readerLength, currentReadLength);
        _readerLength = (UInt32) dataStore.length;
    }
    
    NSData *subData = [dataStore subdataWithRange:range];
    Byte *tempByte = (Byte *)[subData bytes];
    memcpy(data,tempByte,currentReadLength);
    
    
    return currentReadLength;
}

@end
