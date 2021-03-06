//
//  MixMethodStrategy.m
//  CJMix
//
//  Created by ChenJie on 2019/1/24.
//  Copyright © 2019 Chan. All rights reserved.
//

#import "MixMethodStrategy.h"
#import "MixStringStrategy.h"
#import "MixFileStrategy.h"
#import "MixJudgeStrategy.h"
#import "../Config/MixConfig.h"

@implementation MixMethodStrategy

+ (NSString *)methodFromData:(NSString *)data {
    
    NSString * copyData = [data stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    NSString * empty = [MixStringStrategy filterOutImpurities:data];
    
    if (![empty hasPrefix:@"("]) {
        return nil;
    }
    
    NSRange bracketRange = [copyData rangeOfString:@")"];
    NSString * methodStr = nil;
    if (bracketRange.location != NSNotFound) {
        methodStr = [copyData substringFromIndex:bracketRange.location + bracketRange.length];
        
        if ([methodStr containsString:@"{"] || [methodStr containsString:@";"]) {
            NSRange range1 = [methodStr rangeOfString:@"{"];
            NSRange range2 = [methodStr rangeOfString:@";"];
            NSInteger location = NSNotFound;
            if (range1.location != NSNotFound) {
                location = range1.location;
            }
            if (range2.location != NSNotFound) {
                if (range2.location < location) {
                    location = range2.location;
                }
            }
            
            if (location != NSNotFound) {
                methodStr = [methodStr substringToIndex:location];
            } else {
                methodStr = nil;
            }
        }
    }
    
    
    if (!methodStr) {
        return nil;
    }
    
    //已取到方法范围
    if ([methodStr containsString:@":"]) {
        //有参数方法
        NSArray <NSString *>* names = [methodStr componentsSeparatedByString:@":"];
        NSMutableArray <NSString *>* methodNames = [NSMutableArray arrayWithCapacity:0];
        
        for (NSString * name in names) {
            
            //判断是否最后
            if ([name isEqual:names.lastObject]) {
                break;
            }
            
            //是否有括号
            NSRange range = [name rangeOfString:@")"];
            if (range.location != NSNotFound) {
                NSString * methodStr = [name substringFromIndex:range.location + range.length];
                //只有方法参数
                if ([MixStringStrategy isAlphaNumUnderline:methodStr]) {
                    [methodNames addObject:methodStr];
                } else {
                    //说明有参数和方法参数
                    if ([methodStr containsString:@" "]) {
                        NSArray * blanks = [methodStr componentsSeparatedByString:@" "];
                        for (int ii = (int)blanks.count - 1; ii > 0; ii--) {
                            NSString * str = blanks[ii];
                            if (str.length) {
                                methodStr = str;
                                break;
                            }
                        }
                        if ([MixStringStrategy isAlphaNumUnderline:methodStr]) {
                            [methodNames addObject:methodStr];
                        }
                    }
                }
            } else {
                NSString * minus = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
                if ([MixStringStrategy isAlphaNumUnderline:minus]) {
                    [methodNames addObject:minus];
                }
            }
            
        }
        
        NSString *methodInfo = nil;
        if (methodNames.count) {
            methodInfo = [NSString stringWithFormat:@"%@:",[methodNames componentsJoinedByString:@":"]];
        }
        return methodInfo;
        
    } else {
        //无参数方法
        NSArray * names = [methodStr componentsSeparatedByString:@" "];
        if (names.count) {
            for (NSString * name in names) {
                if (name.length) {
                    methodStr = name;
                    break;
                }
            }
        }
        
        if ([MixStringStrategy isAlphaNumUnderline:methodStr]) {
            return methodStr;
        }
    }
   
    
    return nil;
}

+ (NSArray <NSString *>*)methodsWithPath:(NSString *)path {
    NSArray <MixFile *> *files = [MixFileStrategy filesWithPath:path framework:YES];
    NSArray<MixFile *> *hmFiles = [MixFileStrategy filesToHMFiles:files];
    
    NSMutableArray <NSString *> * methods = [NSMutableArray arrayWithCapacity:0];
    
    for (MixFile * obj in hmFiles) {
        @autoreleasepool {
            [methods addObjectsFromArray:[MixMethodStrategy methodsWithData:obj.data]];
        }
    }
    
    return methods;
}


+ (NSArray <NSString *>*)methods:(NSArray <MixObject *>*)objects {
    
    NSMutableArray <NSString *> * methods = [NSMutableArray arrayWithCapacity:0];
    
    for (MixObject * obj in objects) {
        @autoreleasepool {
            if (obj.classFile.hFile) {
                [methods addObjectsFromArray:[MixMethodStrategy methodsWithData:obj.classFile.hFile.data]];
            }
            if (obj.classFile.mFile) {
                [methods addObjectsFromArray:[MixMethodStrategy methodsWithData:obj.classFile.mFile.data]];
            }
        }
    }
    
    NSMutableArray * worker = [NSMutableArray arrayWithCapacity:0];
    for (NSString * obj in methods) {
        if ([MixJudgeStrategy isIllegalMethod:obj]) {
            //        printf("深坑:%s\n",[oldMethod UTF8String]);
            continue;
        }
        if (![worker containsObject:obj]) {
            [worker addObject:obj];
        }
    }
    
    return worker;
}


+ (NSArray <NSString *>*)methodsWithData:(NSString *)data {
    if (!data) {
        return @[];
    }
    
    NSMutableArray <NSString *>* methods = [NSMutableArray arrayWithCapacity:0];
    
    NSArray <NSString *>* interface = [data componentsSeparatedByString:@"@interface"];
    
    [interface enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx != 0) {
            NSRange range = [obj rangeOfString:@"@end"];
            if (range.location != NSNotFound) {
                NSString * str = [obj substringToIndex:range.location];
                [methods addObjectsFromArray:[MixMethodStrategy methodsWithClassData:str isInterface:YES]];
            }
        }
    }];
    
    
    NSArray <NSString *>* implementations = [data componentsSeparatedByString:@"@implementation"];
    [implementations enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx != 0) {
            NSRange range = [obj rangeOfString:@"@end"];
            if (range.location != NSNotFound) {
                NSString * str = [obj substringToIndex:range.location];
                [methods addObjectsFromArray:[MixMethodStrategy methodsWithClassData:str]];
            }
        }
    }];
    
    
    NSArray <NSString *>* protocol = [data componentsSeparatedByString:@"@protocol"];
    [protocol enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx != 0) {
            NSRange range = [obj rangeOfString:@"@end"];
            if (range.location != NSNotFound) {
                NSString * str = [obj substringToIndex:range.location];
                [methods addObjectsFromArray:[MixMethodStrategy methodsWithClassData:str]];
            }
        }
    }];
    
    
    return methods;
}

+ (NSArray <NSString *>*)methodsWithClassData:(NSString *)data isInterface:(BOOL)isInterface {
    
    NSString * temp = [MixStringStrategy filterEscapeCharacter:data];
    NSArray * strs = [temp componentsSeparatedByString:@" "];
    bool isShieldClass = NO;
    for (NSString * str in strs) {
        if (str.length) {
            isShieldClass = [MixJudgeStrategy isShieldPropertyWithClass:str];
            break;
        }
    }
    
    NSMutableArray <NSString *>* methods = [NSMutableArray arrayWithCapacity:0];
    
    NSArray <NSString *>* addMethodData = [data componentsSeparatedByString:@"+"];
    NSArray <NSString *>* subMethodData = [data componentsSeparatedByString:@"-"];
    
    [addMethodData enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx != 0) {
            NSString * group = [NSString stringWithFormat:@"%@",obj];
            NSString * method = [MixMethodStrategy methodFromData:group];
            if (method && ![methods containsObject:method]) {
                [methods addObject:method];
            }
        }
    }];
    
    [subMethodData enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx != 0) {
            NSString * group = [NSString stringWithFormat:@"%@",obj];
            NSString * method = [MixMethodStrategy methodFromData:group];
            if (method && ![methods containsObject:method]) {
                [methods addObject:method];
            }
        }
    }];
    
    
    
    NSArray <NSString *>* propertyMethodData = [data componentsSeparatedByString:@"@property"];
    [propertyMethodData enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx != 0) {
            NSRange range = [obj rangeOfString:@";"];
            if (range.location != NSNotFound) {
                
                NSString * property = [obj substringToIndex:range.location];
                
                
                if ([property containsString:@"getter"]) {
                    NSRange getterRange = [property rangeOfString:@"getter"];
                    NSString * methodStr = nil;
                    if (getterRange.location != NSNotFound) {
                        methodStr = [property substringFromIndex:getterRange.location + getterRange.length];
                        NSRange range1 = [methodStr rangeOfString:@")"];
                        NSRange range2 = [methodStr rangeOfString:@","];
                        NSInteger location = NSNotFound;
                        if (range1.location != NSNotFound) {
                            location = range1.location;
                        }
                        if (range2.location != NSNotFound) {
                            if (range2.location < location) {
                                location = range2.location;
                            }
                        }
                        
                        if (location != NSNotFound) {
                            methodStr = [methodStr substringToIndex:location];
                            
                            methodStr = [methodStr stringByReplacingOccurrencesOfString:@"=" withString:@""];
                            methodStr = [methodStr stringByReplacingOccurrencesOfString:@" " withString:@""];
                            
                            if (methodStr.length) {
                                if ([MixStringStrategy isAlphaNumUnderline:methodStr]) {
                                    
                                    if (![methods containsObject:methodStr]) {
                                        [methods addObject:methodStr];
                                    }
                                    
                                    if (isShieldClass) {
                                        
                                        if (![[MixConfig sharedSingleton].shieldProperty containsObject:methodStr]) {
                                            [[MixConfig sharedSingleton].shieldProperty addObject:methodStr];
                                        }
                                    
                                    }
                                }
                            }
                            
                        }
                    }
                }
                
                BOOL isOnlyRead = [property containsString:@"readonly"];
                
                NSString * propertyName = nil;
                if ([property containsString:@"^"]) {//block
                    NSArray * strs = [property componentsSeparatedByString:@"^"];
                    if (strs.count>1) {
                        NSString * lastStr = strs.lastObject;
                        NSArray * strs = [lastStr componentsSeparatedByString:@")"];
                        if (strs.count>1) {
                            strs = [strs.firstObject componentsSeparatedByString:@" "];
                            if (strs.count>=1) {
                                NSString *str = strs.lastObject;
                                if (str.length) {
                                    if ([MixStringStrategy isAlphaNumUnderline:str]) {
                                        propertyName = str;
                                    }
                                }
                            }
                        }
                    }
                }else if ([property containsString:@"*"]) {
                    //强引用
                    NSArray * strs = [property componentsSeparatedByString:@"*"];
                    if (strs.count) {
                        NSString * lastStr = strs.lastObject;
                        
                        NSArray * strs = [lastStr componentsSeparatedByString:@" "];
                        for (NSString * str in strs) {
                            if (str.length) {
                                if ([MixStringStrategy isAlphaNumUnderline:str]) {
                                    propertyName = str;
                                    break;
                                }
                            }
                        }
                        
                        
                    }
                    
                }else {
                    //弱引用
                    NSArray * strs = [property componentsSeparatedByString:@" "];
                    for (int i = (int)strs.count-1; i > 0; i--) {
                        NSString * str = strs[i];
                        if (str.length) {
                            if ([MixStringStrategy isAlphaNumUnderline:str]) {
                                propertyName = str;
                                break;
                            }
                        }
                    }
                    
                }
                
                if (propertyName.length) {
                    
                    if (![methods containsObject:propertyName]) {
                        [methods addObject:propertyName];
                    }
                    
                    NSString * setPropertyName = nil;
                    if (!isOnlyRead) {
                        setPropertyName = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[propertyName substringToIndex:1] uppercaseString]];
                        
                        setPropertyName = [NSString stringWithFormat:@"set%@:",setPropertyName];
                        if (![methods containsObject:setPropertyName]) {
                            [methods addObject:setPropertyName];
                        }
                    }
                    
                    
                    if (isShieldClass) {
                        
                        if (![[MixConfig sharedSingleton].shieldProperty containsObject:propertyName]) {
                            [[MixConfig sharedSingleton].shieldProperty addObject:propertyName];
                        }
                        
                        if (setPropertyName && ![[MixConfig sharedSingleton].shieldProperty containsObject:setPropertyName]) {
                            [[MixConfig sharedSingleton].shieldProperty addObject:setPropertyName];
                        }
                    }
                }
            }
        }
    }];
    
    return methods;
    
    
}

+ (NSArray <NSString *>*)methodsWithClassData:(NSString *)data {
    return [MixMethodStrategy methodsWithClassData:data isInterface:NO];
}


@end
