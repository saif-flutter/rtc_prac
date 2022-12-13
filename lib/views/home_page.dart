import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _localRendrer=RTCVideoRenderer();
  late MediaStream _localStream;
  final _remoteRendrer=RTCVideoRenderer();
  late RTCPeerConnection _peerConnection;
  @override
  void initState() {
    initRenderers();
    _createPeerConnection().then((pc){
      _peerConnection=pc;
    });
    super.initState();
  }
  initRenderers()async
  {
    await _localRendrer.initialize();
    await _remoteRendrer.initialize();
  }

  getMedia()async
  {
    final settings={
      'audio':'false',
      'video':{
        'facingMode':'user'
      }
    };
    MediaStream stream=await navigator.getUserMedia(settings);
    _localRendrer.srcObject=stream;
    return stream;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
           Positioned(
            top: 0,
              right: 0,
              left: 0,
              bottom: 0,
              child: RTCVideoView(
                _remoteRendrer
              )
          ),
          Positioned(
            top: 20,
            right: 20,
            height: 200,
            width: 100,
            child: RTCVideoView(
              _localRendrer
            ),
          ),

        ],
      ),
    );
  }

 Future<RTCPeerConnection> _createPeerConnection()async {
    final config={
      'iceServers':[
        {'url': 'stun:stun.l.google.com:19302'}
      ]
    };

    final offerConstraints={
      'mandatory':{
        'offerToReceiveAudio':'true',
        'offerToReceiveVideo':'true',
      },
      'optional':[]
    };
    _localStream=await getMedia();
    final pc=await createPeerConnection(config,offerConstraints);
    pc.addStream(_localStream);
    pc.onIceCandidate=(e){
      if(e.candidate!=null){
        print(jsonEncode({
          'candidate':e.candidate.toString(),
          'sdpMid':e.sdpMid.toString(),
          'sdpMLineIndex':e.sdpMLineIndex.toString(),
        }));
      }
    };
    pc.onIceConnectionState=(e){
      print(e);
    };
    pc.onAddStream=(stream){
      print("add stream:${stream.id}");
      _remoteRendrer.srcObject=stream;
    };

    return pc;
  }
}
