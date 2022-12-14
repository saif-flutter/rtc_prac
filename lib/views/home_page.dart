import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

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
  final sdpController=TextEditingController();
  bool _offer=false;
  bool added=true;
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
                _remoteRendrer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                filterQuality: FilterQuality.medium,
                mirror: true,
              )
          ),
          Positioned(
            top: 20,
            right: 20,
            height: MediaQuery.of(context).size.height*0.2,
            width: MediaQuery.of(context).size.width*0.2,
            child: RTCVideoView(
              _localRendrer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              filterQuality: FilterQuality.medium,
              mirror: true,
            ),
          ),

          Positioned(
            right: 0,
            left: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height*0.4,
            child: Visibility(
              visible: added,
              child: Container(
                decoration:  BoxDecoration(
                  borderRadius:const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5
                    )
                  ]
                ),
                child: Column(
                  children: [
                   const  Spacer(),
                    Expanded(
                     flex: 2,
                      child: TextField(
                        maxLines: 4,
                        controller: sdpController,
                        decoration: const InputDecoration(
                          hintText: "Enter your text here"
                        ),
                      ),
                    ),

                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: MaterialButton(
                                color: Colors.blue,
                                textColor: Colors.white,
                                onPressed: _createOffer,
                                child: Text("offer"),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: MaterialButton(
                                color: Colors.blue,
                                textColor: Colors.white,
                                onPressed: _createAnswer,
                                child: Text("Answer"),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: MaterialButton(
                                color: Colors.blue,
                                textColor: Colors.white,
                                onPressed: _setRemoteDescription,
                                child: const FittedBox(child: Text("Set Description")),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:const EdgeInsets.symmetric(horizontal: 10),
                              child: MaterialButton(
                                color: Colors.blue,
                                textColor: Colors.white,
                                onPressed: _addCandidate,
                                child: FittedBox(child: Text("Set Candidate")),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
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
          'sdpMLineIndex':e.sdpMLineIndex,
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


  void _createOffer() async {
    RTCSessionDescription description =
    await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print(json.encode(session));
    _offer = true;

    _peerConnection.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
    await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp.toString());
    print(json.encode(session));

    _peerConnection!.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode('$jsonString');

    String sdp = write(session, null);

    RTCSessionDescription description =
    new RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print(description.toMap());

    await _peerConnection!.setRemoteDescription(description);
  }

  void _addCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode('$jsonString');
    print(session['candidate']);
    dynamic candidate =  RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection!.addCandidate(candidate);
    setState(() {
      added=false;
    });
  }
}
