//
//  MainInterfaceController.swift
//  WatchMusic Extension
//
//  Created by Leo Qin on 2019/9/23.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import WatchKit
import WatchConnectivity
import CoreAudio
import CoreData
import AVFoundation
import Foundation
import WatchMusicModel


class MainInterfaceController: WKInterfaceController {

    @IBOutlet weak var mainTable: WKInterfaceTable!
    var player: AVAudioPlayer!
    
    var managedObjectContext: NSManagedObjectContext!
    
    var session: WCSession!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        let mainTitleArr = [
            "正在播放",
            "所有歌曲",
            "我喜欢"
        ]
        
        mainTable.setNumberOfRows(mainTitleArr.count, withRowType: "MainTableRowController")
        for(idx, item) in mainTitleArr.enumerated() {
            let cell = mainTable.rowController(at: idx) as! MainTableRowController
            cell.titleLabel.setText(item)
        }

    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}


extension MainInterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print(file)
        
        do {
            let data = try Data(contentsOf: file.fileURL)
            
            let asset = AVURLAsset(url: file.fileURL)
            
            for format in asset.availableMetadataFormats {
                let metaItems = asset.metadata(forFormat: format)
                for item in metaItems where item.commonKey != nil {
                    switch item.commonKey! {
                    case .commonKeyAlbumName:
                        break
                    default:
                        <#code#>
                    }
            
                    print(item.value)
                }
            }
            
            /*
             NSString *songsDirectory=MUSIC_FILE_ALL;//沙盒地址
                NSBundle *songBundle=[NSBundle bundleWithPath:songsDirectory];
                NSString *bundlePath=[songBundle resourcePath];
             
                NSArray *arrMp3=[NSBundle pathsForResourcesOfType:@"mp3" inDirectory:bundlePath];
                for (NSString *filePath in arrMp3) {
                    [self.wMp3URL addObject:filePath];
                }

             -(void)mDefineUpControl{
                 NSString *filePath = [self.wMp3URL objectAtIndex: 0 ];//随便取一个，说明
                 //文件管理，取得文件属性

                 NSFileManager *fm = [NSFileManager defaultManager];
                 NSDictionary *dictAtt = [fm attributesOfItemAtPath:filePath error:nil];
                 

                 //取得音频数据

                 NSURL *fileURL=[NSURL fileURLWithPath:filePath];
                 AVURLAsset *mp3Asset=[AVURLAsset URLAssetWithURL:fileURL options:nil];
               
                 
                 NSString *singer;//歌手
                 NSString *song;//歌曲名

                 UIImage *image;//图片

                 NSString *albumName;//专辑名
                 NSString *fileSize;//文件大小
                 NSString *voiceStyle;//音质类型
                 NSString *fileStyle;//文件类型
                 NSString *creatDate;//创建日期
                 NSString *savePath; //存储路径
                 
                 for (NSString *format in [mp3Asset availableMetadataFormats]) {
                     for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
                         if([metadataItem.commonKey isEqualToString:@"title"]){
                             song = (NSString *)metadataItem.value;//歌曲名
                        
                         }else if ([metadataItem.commonKey isEqualToString:@"artist"]){
                             singer = (NSString *)metadataItem.value;//歌手
                         }
                         //            专辑名称
                         else if ([metadataItem.commonKey isEqualToString:@"albumName"])
                         {
                             albumName = (NSString *)metadataItem.value;
                         }else if ([metadataItem.commonKey isEqualToString:@"artwork"]) {
                             NSDictionary *dict=(NSDictionary *)metadataItem.value;
                             NSData *data=[dict objectForKey:@"data"];
                             image=[UIImage imageWithData:data];//图片
                         }
                     
                     }
                 }
                 savePath = filePath;
                 float tempFlo = [[dictAtt objectForKey:@"NSFileSize"] floatValue]/(1024*1024);
                 fileSize = [NSString stringWithFormat:@"%.2fMB",[[dictAtt objectForKey:@"NSFileSize"] floatValue]/(1024*1024)];
                 NSString *tempStrr  = [NSString stringWithFormat:@"%@", [dictAtt objectForKey:@"NSFileCreationDate"]] ;
                 creatDate = [tempStrr substringToIndex:19];
                 fileStyle = [filePath substringFromIndex:[filePath length]-3];
                 if(tempFlo <= 2){
                     voiceStyle = @"普通";
                 }else if(tempFlo > 2 && tempFlo <= 5){
                     voiceStyle = @"良好";
                 }else if(tempFlo > 5 && tempFlo < 10){
                     voiceStyle = @"标准";
                 }else if(tempFlo > 10){
                     voiceStyle = @"高清";
                 }
                 
                 
                 NSArray *tempArr = [[NSArray alloc] initWithObjects:@"歌手:",@"歌曲名称:",@"专辑名称:",@"文件大小:",@"音质类型:",@"文件格式:",@"创建日期:",@"保存路径:", nil];
                 NSArray *tempArrInfo = [[NSArray alloc] initWithObjects:singer,song,albumName,fileSize,voiceStyle,fileStyle,creatDate,savePath, nil];
                 for(int i = 0;i < [tempArr count]; i ++){
                     NSString *strTitle = [tempArr objectAtIndex:i];
                     UILabel *titleLab = [[UILabel alloc] initWithFrame:CGRectMake(5, 5+i*30, 16*[strTitle length], 25)];
                     [titleLab setText:strTitle];
                     [titleLab setTextColor:[WASharedFontStyle mGetSharedFontColor]];
                     [titleLab setFont:[UIFont systemFontOfSize:16]];
                     [self.wInfoSV addSubview:titleLab];
                     
                     NSString *strInfo = [tempArrInfo objectAtIndex:i];
                     UILabel *infoLab = [[UILabel alloc] initWithFrame:CGRectMake(titleLab.frame.origin.x+titleLab.bounds.size.width+5, 5+i*30, self.view.bounds.size.width-(titleLab.frame.origin.x+titleLab.bounds.size.width+5)-5, 25)];
                     [infoLab setText:strInfo];
                     [infoLab setTextColor:[WASharedFontStyle mGetSharedFontColor]];
                     [infoLab setFont:[UIFont systemFontOfSize:16]];
                     [self.wInfoSV addSubview:infoLab];
                     
                     if(i == [tempArr count]-1){
                         [infoLab setFrame:CGRectMake(titleLab.frame.origin.x+titleLab.bounds.size.width+5, 5+i*30, self.view.bounds.size.width-(titleLab.frame.origin.x+titleLab.bounds.size.width+5)-5, 30*4)];
                         [infoLab setLineBreakMode:NSLineBreakByWordWrapping];
                         [infoLab setFont:[UIFont systemFontOfSize:12]];
                         [infoLab setNumberOfLines:0];
                     }
                     
                     [self.wInfoSV setContentSize:CGSizeMake(self.view.bounds.size.width, i*45)];
                     
                 }
                 
                 
                 
             }

             */

            managedObjectContext.performChanges {[unowned self] in
                let _ = Song.insert(into: self.managedObjectContext, songName: file.fileURL.lastPathComponent, songData: data)
            }
            
        } catch {
            
        }
        
        
    }
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print(messageData)
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if rowIndex == 1 {
            pushController(withName: "AllSongsInterfaceController", context: managedObjectContext)
        }
    }
    
    
}
