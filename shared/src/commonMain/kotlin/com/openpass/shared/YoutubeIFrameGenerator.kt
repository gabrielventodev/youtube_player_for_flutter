package com.openpass.shared

object YoutubeIFrameGenerator {

    fun generate(config: PlayerConfig): String {
        val autoPlay = if (config.autoPlay) 1 else 0
        val controls = if (config.showControls) 1 else 0
        val fsButton = if (config.showFullscreenButton) 1 else 0
        val rel = if (config.showRelatedVideos) 1 else 0
        val loop = if (config.loop) 1 else 0
        val playlist = if (config.loop) "'playlist': '${config.videoId}'," else ""

        val startSeconds = if (config.startSeconds > 0) "'start': ${config.startSeconds}," else ""
        val endSeconds = if (config.endSeconds > 0) "'end': ${config.endSeconds}," else ""

        return """<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
<style>*{margin:0;padding:0;overflow:hidden}html,body{width:100%;height:100%;background:#000}#player{width:100%;height:100%}</style>
</head>
<body>
<div id="player"></div>
<script>
var tag=document.createElement('script');
tag.src='https://www.youtube.com/iframe_api';
document.head.appendChild(tag);
var player;
function onYouTubeIframeAPIReady(){
player=new YT.Player('player',{
height:'100%',width:'100%',
videoId:'${config.videoId}',
host:'https://www.youtube-nocookie.com',
playerVars:{
'autoplay':$autoPlay,'controls':$controls,'fs':$fsButton,
'enablejsapi':1,'rel':$rel,'loop':$loop,
'playsinline':1,
$playlist $startSeconds $endSeconds
},
events:{
'onReady':function(e){try{YTBridge.onReady()}catch(x){}},
'onStateChange':function(e){try{YTBridge.onStateChange(e.data)}catch(x){}},
'onError':function(e){try{YTBridge.onError(e.data)}catch(x){}},
'onPlaybackQualityChange':function(e){try{YTBridge.onPlaybackQualityChange(e.data)}catch(x){}}
}
});
}
function ytPlay(){if(player)player.playVideo()}
function ytPause(){if(player)player.pauseVideo()}
function ytSeekTo(s){if(player)player.seekTo(s,true)}
function ytLoadVideo(id,s){if(player){player.loadVideoById(id,s||0)}}
function ytCueVideo(id,s){if(player){player.cueVideoById(id,s||0)}}
function ytSetQuality(q){if(player)player.setPlaybackQuality(q)}
function ytSetVolume(v){if(player)player.setVolume(v)}
function ytMute(){if(player)player.mute()}
function ytUnMute(){if(player)player.unMute()}
function ytGetCurrentTime(){return player?player.getCurrentTime():0}
function ytGetDuration(){return player?player.getDuration():0}
function ytGetQuality(){return player?player.getPlaybackQuality():'default'}
function ytGetAvailableQualities(){return player?JSON.stringify(player.getAvailableQualityLevels()):'[]'}
</script>
</body>
</html>"""
    }
}
