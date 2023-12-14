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
      messages: [
        Messages(
            role: Role.user,
            content:
                "Hello! Please translate follow text into Chinese in json object with key zh-rCN: Hello!\nWorld!\nYou need sleep")
      ],
      maxToken: 200,
      model: GptTurbo1106Model(),
      responseFormat: ResponseFormat(type: "json_object"));

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
    final text = transPromoteCN2.replaceAll("TARGET_LANG", targetLang.cnName);
    return text +
        jsonEncode(strings
            .asMap()
            .map((key, value) => MapEntry(key.toString(), value)));
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
    "我希望你充当语言翻译器.我会发送一段Json格式的文本,你需要将其中的文本内容翻译为TARGET_LANG,一定要是TARGET_LANG.不要写任何解释或其他文字,你的回复需要保持Json的格式,只修改需要翻译的内容,如果翻译后的内容有双引号,请修改为单引号。第一句是: ";

const transPromoteCN2 =
    "作为语言翻译器,你的任务是将我发送的JSON格式文本中的文本内容翻译成TARGET_LANG.请确保不写任何解释或其他文字,保持JSON格式进行回复,只修改需要翻译的内容.如果翻译后的内容包含双引号,请修改为单引号.第一句是: ";

class OpenAiTrans {
  OpenAI? _openAI;
  var _isInit = false;

  // 第次最多翻译多少项: 太大容易太慢, 太小效率不高
  var maxPreRequestCount = 20;

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

  Future<TransResponse?> _transOne(TransData request) async {
    final chat = ChatCompleteText(
        messages: [Messages(role: Role.user, content: request.genPromote())],
        maxToken: 2000,
        topP: 0.8,
        model: GptTurbo1106Model(),
        responseFormat: ResponseFormat(type: "json_object"));
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
      final Map result = jsonDecode(text);
      final resultText =
          result.values.map((e) => fixTranslatedText(e as String)).toList();
      if (request.strings.length != resultText.length) {
        log.d("Response text length is not equal to request");
        return null;
      }
      return TransResponse(request.targetLang, request.keys, resultText,
          start: request.start, count: request.count);
    }
  }

  // 修正翻译后的文本
  String fixTranslatedText(String text) {
    // 目前是将单引号增加转义
    return text.replaceAll("'", "\\'");
  }

  Future<void> startTransRequest(
      TransRequest request, Function(TransResponse?) callback) async {
    // 拆分成小的请求进行翻译
    if (request.strings.length > maxPreRequestCount) {
      final subRequests = request.split(maxPreRequestCount);
      for (var subRequest in subRequests) {
        final resp = await _transOne(subRequest);
        callback(resp);
      }
      return;
    } else {
      final resp = await _transOne(request);
      callback(resp);
    }
  }
}
