import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import '../data/language.dart';

const _token = "ak-JPfYBxjYgKpVQ7WnE4nFmQuhN3Jl5zC0jdX4CuClFBWUSoFK";

const _apkUrl = "https://api.nextweb.fun/openai/v1/";

void chatCompleteTest() async {
  final openAI = OpenAI.instance.build(
      token: _token,
      apiUrl: _apkUrl,
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
  late OpenAI _openAI;
  var _isInit = false;

  // 第次最多翻译20项
  var maxPreRequestCount = 20;

  void init() {
    if (_isInit) return;
    _openAI = OpenAI.instance.build(
        token: _token,
        apiUrl: _apkUrl,
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
        enableLog: true);
    _isInit = true;
  }

  Future<TransResponse?> transOne(TransData request) async {
    final chat = ChatCompleteText(
        messages: [Messages(role: Role.user, content: request.genPromote())],
        maxToken: 2000,
        model: GptTurboChatModel());
    final response = await _openAI.onChatCompletion(request: chat);
    if (response == null) {
      return null;
    } else {
      final text = response.choices.first.message?.content;
      if (text == null) {
        log("Response is null");
        return null;
      }
      log("Response text:$text");
      final List result = jsonDecode(text);
      final resultText = result.map((e) => e as String).toList();
      if (request.strings.length != resultText.length) {
        log("Response text length is not equal to request");
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
