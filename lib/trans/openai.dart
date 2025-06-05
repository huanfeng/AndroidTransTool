import 'dart:async';
import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import '../data/language.dart';
import '../global.dart';
import '../pages/home.dart';
import 'trans_data.dart';

typedef TranslateProgressCallback = void Function(TranslateProgress progress);

void chatCompleteTest(String apiUrl, String apiToken,
    {String? httpProxy, TranslateProgressCallback? callback}) async {
  final openAI = OpenAI.instance.build(
      token: apiToken,
      apiUrl: apiUrl,
      baseOption: HttpSetup(
          receiveTimeout: const Duration(seconds: 10),
          proxy: httpProxy != null && httpProxy.isNotEmpty ? "PROXY $httpProxy" : ""),
      enableLog: true);

  final request = ChatCompleteText(
      messages: [
        Messages(
                role: Role.user,
                content:
                    "Hello! Please translate follow text into Chinese in json object with key zh-rCN: Hello!\nWorld!\nYou need sleep")
            .toJson()
      ],
      maxToken: 200,
      model: Gpt4oMiniChatModel(),
      responseFormat: ResponseFormat(type: "json_object"));

  final response = await openAI.onChatCompletion(request: request);
  for (var element in response!.choices) {
    log.i("data -> ${element.message?.content}");
  }
}

class TransPromote {
  static const kTargetLang = "TARGET_LANG";

  // static const transPromoteCN =
  //     "我希望你充当语言翻译器.我会发送一段Json格式的文本,你需要将其中的文本内容翻译为TARGET_LANG,一定要是TARGET_LANG.不要写任何解释或其他文字,你的回复需要保持Json的格式,只修改需要翻译的内容,如果翻译后的内容有双引号,请修改为单引号。第一句是: ";

  static const transPromoteCN =
      "作为语言翻译器,你的任务是将我发送的JSON格式文本中的文本内容翻译成TARGET_LANG.请确保不写任何解释或其他文字,保持JSON格式进行回复,只修改需要翻译的内容.如果翻译后的内容包含双引号,请修改为单引号.";

  static const transPromoteEN =
      "As a language translator, your task is to translate the text content in the JSON format text I send into TARGET_LANG. Please ensure not to write any explanations or other text, maintain the JSON format for replies, only modifying the content that needs translation. If the translated content includes double quotes, please change them to single quotes.";

  static const transPromoteCHT =
      "作為語言翻譯器，你的任務是將我發送的JSON格式文本中的文本內容翻譯成TARGET_LANG。請確保不寫任何解釋或其他文字，保持JSON格式進行回覆，只修改需要翻譯的內容。如果翻譯後的內容包含雙引號，請修改為單引號。";

  static String getTransPromote(Language targetLang) {
    switch (targetLang) {
      case Language.cn:
        return transPromoteCN.replaceAll(kTargetLang, targetLang.cnName);
      case Language.cnTw:
      case Language.cnHk:
        return transPromoteCHT.replaceAll(kTargetLang, targetLang.cnName);
      default:
        return transPromoteEN.replaceAll(kTargetLang, targetLang.enName);
    }
  }
}

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
            receiveTimeout: const Duration(seconds: 120),
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
        messages: [
          Messages(
                  role: Role.system,
                  content: TransPromote.getTransPromote(request.targetLang))
              .toJson(),
          Messages(role: Role.user, content: request.toJson()).toJson()
        ],
        maxToken: 4000,
        topP: 0.8,
        model: Gpt4oMiniChatModel(),
        responseFormat: ResponseFormat.jsonObject);
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
      var transCount = 0;
      for (var e in result.entries) {
        final key = e.key as String;
        final value = e.value;
        if (value is String) {
          final item = request.getItem(key);
          if (item != null) {
            item.dstValue = _fixTranslatedText(value);
            transCount++;
          }
        } else if (value is List) {
          final item = request.getItem(key);
          if (item != null) {
            final list =
                value.map((e) => _fixTranslatedText(e as String)).toList();
            item.dstValue = list;
            transCount++;
          }
        }
      }
      if (request.items.length != transCount) {
        log.w("Response text length is not equal to request");
      }
      return TransResponse(request.targetLang, request.items,
          start: request.start, count: request.count);
    }
  }

  // 修正翻译后的文本
  String _fixTranslatedText(String text) {
    // 目前是将单引号增加转义
    return text.replaceAll("'", "\\'");
  }

  Future<void> startTransRequest(
      TransRequest request, Function(TransResponse?) callback) async {
    // 拆分成小的请求进行翻译
    if (request.items.length > maxPreRequestCount) {
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
