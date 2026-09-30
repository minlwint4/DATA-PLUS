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

  // 🚀 ဖုန်းစနစ် (Chrome / Downloader App) ဆီ လွှဲပြောင်းပေးသည့် Function
  Future<void> _launchExternal(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Launch external URL error: $e');
    }
  }

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
            final lowerUrl = url.toLowerCase();

            // 🚀 ၁။ dataplus:// scheme လာပါက DATA PLUS Downloader app ကို တိုက်ရိုက်ဖွင့်ပေးခြင်း
            if (url.startsWith('dataplus://')) {
              await _launchExternal(url);
              return NavigationDecision.prevent;
            }

            // 📥 ၂။ app.py ရှိ /api/download/apk သို့မဟုတ် .apk ဒေါင်းလုဒ်လင့်ခ်များကို
            // ဖုန်း၏ မူရင်း Browser (Chrome) Downloader ဆီ တိုက်ရိုက် လွှဲပေးခြင်း
            if (lowerUrl.contains('/api/download/apk') ||
                lowerUrl.contains('.apk') ||
                lowerUrl.contains('.zip')) {
              await _launchExternal(url);
              return NavigationDecision.prevent; // WebView ထဲ မဝင်စေဘဲ Browser ဆီ လွှဲမည်
            }

            // ၃။ အခြား External Scheme များ (intent, tel, etc.)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              await _launchExternal(url);
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
        // ဖုန်း၏ Back ခလုတ်နှိပ်ပါက စာမျက်နှာအဟောင်းသို့ ပြန်ဆုတ်ခြင်း
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
