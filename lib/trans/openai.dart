import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import '../data/language.dart';
import '../global.dart';

void chatCompleteTest(String apiUrl, String apiToken) async {
  final openAI = OpenAI.instance.build(
      token: apiToken,
      apiUrl: apiUrl,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
      enableLog: true);

  final request = ChatCompleteText(
      messages: [Messages(role: Role.user, content: "Hello!")],
      maxToken: 200,
      model: GptTurboChatModel());

  final response = await openAI.onChatCompletion(request: request);
  for (var element in response!.choices) {
    print("data -> ${element.message?.content}");
  }
}

sealed class TransData {
  final bool isRequest;
  final Language targetLang;
  final List<String> keys;
  final List<String> strings;
  int start = 0;
  int count = 0;

  TransData(this.targetLang, this.keys, this.strings,
      {this.start = 0, int? count, this.isRequest = true}) {
    this.count = count ?? strings.length;
  }

  @override
  String toString() {
    return 'TransData{targetLang: $targetLang, start: $start, count: $count}';
  }

  String genPromote() {
    final text = transPromoteCN.replaceAll("TARGET_LANG", targetLang.cnName);
    return text + jsonEncode(strings);
  }
}

class TransRequest extends TransData {
  TransRequest(super.targetLang, super.keys, super.strings,
      {super.start, super.count, super.isRequest = true});

  List<TransRequest> split(int size) {
    final result = <TransRequest>[];
    var start = 0;
    while (start < strings.length) {
      final end = math.min(start + size, strings.length);
      final subKeys = keys.sublist(start, end);
      final subStrings = strings.sublist(start, end);
      result.add(TransRequest(
        targetLang,
        subKeys,
        subStrings,
      ));
      start = end;
    }
    return result;
  }
}

class TransResponse extends TransData {
  TransResponse(super.targetLang, super.keys, super.strings,
      {super.start, super.count, super.isRequest = false});
}

const transPromoteCN =
    "我希望你充当语言翻译器。我会发送一段Json格式的文本，你需要将其中的文本内容翻译为TARGET_LANG，一定要是TARGET_LANG。不要写任何解释或其他文字，你的回复需要保持Json的格式, 只修改需要翻译的内容。第一句是: ";

class OpenAiTrans {
  OpenAI? _openAI;
  var _isInit = false;

  // 第次最多翻译30项
  var maxPreRequestCount = 30;

  var _apiUrl = "";
  var _apiToken = "";
  var _httpProxy = "";

  void _ensureInit() {
    if (_isInit) return;
    if (_apiUrl.isEmpty) {
      throw Exception("apiUrl is empty");
    }
    if (_apiToken.isEmpty) {
      throw Exception("apiToken is empty");
    }
    _openAI = OpenAI.instance.build(
        token: _apiToken,
        apiUrl: _apiUrl,
        baseOption: HttpSetup(
            receiveTimeout: const Duration(seconds: 10),
            proxy: _httpProxy.isNotEmpty ? "PROXY $_httpProxy" : ""),
        enableLog: true);
    _isInit = true;
  }

  OpenAI _ensureOpenAi() {
    _ensureInit();
    return _openAI!;
  }

  void setConfig(String url, String token, {String httpProxy = ""}) {
    if (_apiUrl != url || _apiToken != token || _httpProxy != httpProxy) {
      _apiUrl = url;
      _apiToken = token;
      _httpProxy = httpProxy;
      _isInit = false;
    }
  }

  Future<TransResponse?> transOne(TransData request) async {
    final chat = ChatCompleteText(
        messages: [Messages(role: Role.user, content: request.genPromote())],
        maxToken: 2000,
        model: GptTurboChatModel());
    final openAi = _ensureOpenAi();
    final response = await openAi.onChatCompletion(request: chat);
    if (response == null) {
      return null;
    } else {
      final text = response.choices.first.message?.content;
      if (text == null) {
        log.d("Response is null");
        return null;
      }
      log.d("Response text:$text");
      final List result = jsonDecode(text);
      final resultText = result.map((e) => e as String).toList();
      if (request.strings.length != resultText.length) {
        log.d("Response text length is not equal to request");
        return null;
      }
      return TransResponse(request.targetLang, request.keys, resultText,
          start: request.start, count: request.count);
    }
  }

  Stream<TransResponse?> transTexts(TransRequest request) async* {
    if (request.strings.length > maxPreRequestCount) {
      final subRequests = request.split(maxPreRequestCount);
      for (var subRequest in subRequests) {
        final resp = await transOne(subRequest);
        yield resp;
      }
      return;
    } else {
      final resp = await transOne(request);
      yield resp;
    }
  }
}
