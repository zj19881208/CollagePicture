# Uncomment the next line to define a global platform for your project
# pod outdated
platform:ios,9.0

source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
#source 'https://github.com/CocoaPods/Specs.git'
#忽略警告
inhibit_all_warnings!
#使用动态库，不用静态库加载，优化APP体积
use_frameworks!

target "CollagePicture" do

#通用标准库

pod 'AFNetworking' , '4.0.0'
pod 'SDWebImage','5.6.1'
#pod 'AFNetworking-Synchronous', '~> 1.1.0'
#pod 'SDWebImage/GIF'
#可选 使用WebP
#pod 'SDWebImage/WebP’
pod 'MBProgressHUD', '1.2.0'
pod 'Masonry', '1.1.0'
pod 'Mantle', '2.1.1'
#刷新
pod 'MJRefresh', '3.2.2'
#本地存储
pod 'FMDB', '~> 2.7.5'
pod 'TMCache', '~> 2.1.0'


#工具
pod 'WebViewJavascriptBridge', '6.0.3'
#pod 'AvoidCrash', '~> 2.3.0-beta'

pod 'SVPullToRefresh', '~> 0.4.1'

#第三方平台
pod 'BmobSDK'

pod 'AliyunOSSiOS'
pod 'AlipaySDK-iOS', '15.6.8'

#友盟开发阶段进行调试SDK及相关功能使用，可在发布 App 前移除
# pod 'UMCCommonLog'

 #友盟统计
 pod 'UMCCommon'
 
 #友盟推送-自动依赖UMCCommon
 pod 'UMCPush','3.2.4'

# 高德地图
 pod 'AMapLocation', '2.6.5'
 pod 'AMap2DMap', '5.6.1'
 
 # U-Share SDK UI模块（分享面板，建议添加）
  pod ‘UMengUShare/UI’
 # 集成微信(精简版0.2M)
  pod ‘UMengUShare/Social/ReducedWeChat'
  

#微信SDK UMShare已经有了，如果需要则删除本地的
#  pod 'WechatOpenSDK'


#第三方UI库
pod 'TZImagePickerController', '~> 3.3.1'
pod 'HMSegmentedControl', '~> 1.5.5'
pod 'THSegmentedPager', '~> 1.1.3'

end
