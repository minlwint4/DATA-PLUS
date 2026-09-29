
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DataPlusViewerApp());
}

class DataPlusViewerApp extends StatelessWidget {
  const DataPlusViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DATA PLUS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  // ဆာဗာ၏ Local IP လိပ်စာ
  final String _initialUrl = 'http://10.10.10.10:1000';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;

            // 🚀 dataplus:// scheme လာပါက DATA PLUS Downloader app ဆီ တိုက်ရိုက် လွှဲပြောင်းဖွင့်ပေးခြင်း
            if (url.startsWith('dataplus://')) {
              try {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Launch dataplus error: $e');
              }
              return NavigationDecision.prevent;
            }

            // တခြား External Scheme များ (intent, tel, etc.) ကိုလည်း ဖုန်းစနစ်ဆီ လွှဲပေးခြင်း
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              try {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Launch external error: $e');
              }
              return NavigationDecision.prevent;
            }

            // ပုံမှန် ဝဘ်စာမျက်နှာများကို WebView အတွင်း၌သာ ဆက်လက်ပြသမည်
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // ဖုန်း၏ Back ခလုတ်နှိပ်ပါက စာမျက်နှာအဟောင်းသို့ ပြန်ဆုတ်ခြင်း (App တန်းထွက်မသွားစေရန်)
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFF0275D8),
                  minHeight: 3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
